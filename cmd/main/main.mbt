async fn main raise {
  let request_body : Json = {
    "name": "moonbit",
    "phase": 1,
    "test": true,
  }

  let (response, body) = @http.post(
    "https://httpbin.org/post",
    request_body,
    headers={
      "Content-Type": "application/json",
    },
  )

  println("status code: \{response.code}")
  println("response body: \{body.text()}")
}
