const http = require("http");
const data = JSON.stringify({ email: "abc@gmail.com", password: "password123" });
const req = http.request("http://localhost:3001/api/v1/auth/login", {
  method: "POST",
  headers: { "Content-Type": "application/json", "Content-Length": data.length }
}, (res) => {
  let body = "";
  res.on("data", (chunk) => body += chunk);
  res.on("end", () => {
    const token = JSON.parse(body).accessToken;
    http.get("http://localhost:3001/api/v1/organizations/ecc98bb6-8015-4c97-8766-0a8cde768af1/projects", {
      headers: { Authorization: "Bearer " + token }
    }, (res2) => {
      let body2 = "";
      res2.on("data", (chunk) => body2 += chunk);
      res2.on("end", () => console.log("RESPONSE:", body2));
    });
  });
});
req.write(data);
req.end();
