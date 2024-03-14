'use strict';
let jwt = require('jsonwebtoken');

// Detailed explanations on Google OpenID Connect
// https://developers.google.com/identity/protocols/oauth2/openid-connect

const iss = 'accounts.google.com';
const email = 'jouan69@gmail.com';

// From https://www.googleapis.com/oauth2/v1/certs
// update is infrequent

let token_key = 'id_token'

var https = require('https');
const ssm = new (require('aws-sdk/clients/ssm'))();

function httpRequest() {
    var optionsget = {
        host : 'www.googleapis.com',
        port : 443,
        path : '/oauth2/v1/certs',
        method : 'GET'
    };
    return new Promise(function(resolve, reject) {
        var req = https.request(optionsget, function(res) {
            // reject on bad status
            if (res.statusCode < 200 || res.statusCode >= 300) {
                return reject(new Error('statusCode=' + res.statusCode));
            }
            // cumulate data
            var body = [];
            res.on('data', function(chunk) {
                body.push(chunk);
            });
            // resolve on end
            res.on('end', function() {
                try {
                    body = JSON.parse(Buffer.concat(body).toString());
                } catch(e) {
                    reject(e);
                }
                resolve(body);
            });
        });
        // reject on request error
        req.on('error', function(err) {
            // This is not a "Second reject", just a different sort of failure
            reject(err);
        });
        // IMPORTANT
        req.end();
    });
}

async function checkSSM(initial_key){
    const params = {
        Name: `/google_cert/${initial_key}`
    };
    try{
        let res = await ssm.getParameter(params).promise();
        return res
    } catch (e){
        return Promise.resolve(null)
    }
}

async function putSSM(certMap){
    for (const [key, value] of Object.entries(certMap)) {
        const params = {
            Name: `/google_cert/${key}`,
            Value: `${value}`,
            Overwrite: true,
            Type: `String`
        };
        await ssm.putParameter(params).promise();
    }
}


async function purgeSSM(){
    const params = {
        Path: '/google_cert',
        Recursive: true
    };
    let res = await ssm.getParametersByPath(params).promise();
    let paramsToDelete = []
    for(let param of res['Parameters']){
        paramsToDelete.push(param['Name'])
    }
    if(paramsToDelete.length > 0){
        const oldParams = {
              Names: paramsToDelete
        }
        await ssm.deleteParameters(oldParams).promise();
    }
}


async function getCertif(initial_key){
    let certificate = await checkSSM(initial_key)
    if( certificate == null ){
        await purgeSSM()
        const newCerts = await httpRequest()
        await putSSM(newCerts)
        return newCerts[initial_key]
    } else {
        return certificate['Parameter']['Value']
    }
}


function parseCookies(headers) {
    const parsedCookie = {};
    if (headers.cookie) {
        headers.cookie[0].value.split(';').forEach((cookie) => {
            if (cookie) {
                const parts = cookie.split('=');
                parsedCookie[parts[0].trim()] = parts[1].trim();
            }
        });
    }
    return parsedCookie;
}

const response401 = {
        status: '401',
        statusDescription: 'Unauthorized'
    }
;

function addDefaultDirectoryIndex(olduri) {
    // Match any '/' that occurs at the end of a URI. Replace it with a default index
    return olduri.replace(/\/$/, '\/index.html');
}

exports.handler = async (event, context, callback) => {

    var cfrequest = event.Records[0].cf.request;

    // Adds index.html in subdirectory uri when needed
    cfrequest.uri = addDefaultDirectoryIndex(cfrequest.uri);

    // Authentication
    const headers = cfrequest.headers;
    let accessToken = null;
    if (headers.cookie) {
        let cookies = parseCookies(headers);
        for (let property in cookies) {
            if (cookies.hasOwnProperty(property) && property.includes(token_key)) {
                accessToken = cookies[property];
            }
        }
    }

    // Fail if no authorization header found
    if (accessToken === null) {
        callback('id_token is null', response401);
        return false;
    }

    let jwtToken = accessToken;

    // Fail if the token is not jwt
    let decodedJwt = jwt.decode(jwtToken, {complete: true});
    if (!decodedJwt) {
        callback('id_token is not JWT', response401);
        return false;
    }

    // Fail if token is not delivered by google
    if (decodedJwt.payload.iss !== iss) {
        callback('id_token has wrong issuer', response401);
        return false;
    }

    // Fail if email is not expected one
    // should be replaced by user pool
    if (decodedJwt.payload.email !== email) {
        callback('id_token has wrong associated email', response401);
        return false;
    }

    // Get the kid from the token and retrieve corresponding PEM
    let kid = decodedJwt.header.kid;
    let pem = await getCertif(kid);
    if (!pem) {
        //console.log(JSON.stringify(decodedJwt));
        callback('pem from kid ('+kid+') not found for token '+ JSON.stringify(decodedJwt), response401);
        return false;
    }

    // Verify the signature of the JWT token
    jwt.verify(jwtToken, pem, {issuer: iss}, function (err, payload) {
        if (err) {
            callback(err, response401);
            return false;
        } else {
            // Valid token.
            //console.log('Successful verification');
            //remove authorization header
            delete cfrequest.headers.cookie;
            //CloudFront can proceed to fetch the content from origin
            callback(null, cfrequest);
            return true;
        }
    });
};

