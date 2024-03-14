//import your handler file or main file of Lambda
let handler = require('./authorizer');

const id_token = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjZiYzYzZTlmMThkNTYxYjM0ZjU2NjhmODhhZTI3ZDQ4ODc2ZDgwNzMiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJhY2NvdW50cy5nb29nbGUuY29tIiwiYXpwIjoiODE1OTQ2NzYyNDY1LTYxMmg0ZjhlZW9pbzhjMjRjYmthYWZjamI1YmJqY3BvLmFwcHMuZ29vZ2xldXNlcmNvbnRlbnQuY29tIiwiYXVkIjoiODE1OTQ2NzYyNDY1LTYxMmg0ZjhlZW9pbzhjMjRjYmthYWZjamI1YmJqY3BvLmFwcHMuZ29vZ2xldXNlcmNvbnRlbnQuY29tIiwic3ViIjoiMTE1NzUzNjE4MTYzMDE2MDAzNTk5IiwiZW1haWwiOiJqb3VhbjY5QGdtYWlsLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJhdF9oYXNoIjoiSjNYQVFuQlFXczdMU0JyaEJsNHBEUSIsIm5hbWUiOiJFcndhbiBKb3VhbiIsInBpY3R1cmUiOiJodHRwczovL2xoNS5nb29nbGV1c2VyY29udGVudC5jb20vLW1Tb2NpU0QzeGdZL0FBQUFBQUFBQUFJL0FBQUFBQUFBQUFBL0FNWnV1Y2xXZlB0c01HWFFqQzRqb21vRVFubHFfZUs3V0Evczk2LWMvcGhvdG8uanBnIiwiZ2l2ZW5fbmFtZSI6IkVyd2FuIiwiZmFtaWx5X25hbWUiOiJKb3VhbiIsImxvY2FsZSI6ImZyIiwiaWF0IjoxNTk3ODUwNDQ5LCJleHAiOjE1OTc4NTQwNDksImp0aSI6IjUyMTk5Yzc2MTFmYzEyMjBkNjBhMjM4NzRmOGZhNGVlYjRmYjE0ZDUifQ.Rl2JagLgzX5f_NMDY_PfegnieuhqDAtGUzeWFymL8a2jFL4QXlxA9Y7eVp5QIVa27dkhfpAWkiEJbFoi5x4w9W7D-U1etAxNbaJ9LxM2B_1a5XAa7Z5wQ75pVD2stFjPQjM0FtI67CI4gWTDRzAlPqrmk_zpUBO7EApUHFz9okFDScJKnosz8rBZi2-oBGGbFpLQ5c8FhqR5CyOyyg7sNa1VjiD0lSShRN4tlCLqKDs2QTjG_lRFVbcbD9Cq_0_Ou_W7IQLScEhzPcLbvuBd249K8Hjnl7LuJx08WTekx9uGvFxlghwD7B_cuoUcxU9spA7zM5KStR6fKUwppSvMRg"

//Call your exports function with required params
//In AWS lambda these are event, content, and callback
//event and content are JSON object and callback is a function
//In my example i'm using empty JSON

const event = {
    "Records": [
      {
        "cf": {
          "request": {
            "headers": {
              "cookie": [
                  {
                    "value":"id_token="+id_token+";"
                  }
              ]
            },
            "method": "GET",
            "querystring": "",
            "uri": "/"
          }
        }
      }
    ]
  }

handler.handler( event, //event
    {}, //content
    function(data,ss) {  //callback function with two arguments 
        console.log(data);
        console.log(ss); 
    });