const express = require("express");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

app.get("/", (req,res)=>{
  res.send("Backend PIX funcionando");
});

app.post("/pix/criar",(req,res)=>{

  const {valor,email} = req.body;

  res.json({
    id: Date.now(),
    qr: "00020126580014BR.GOV.BCB.PIX..."
  });

});

app.listen(3000,()=>{
  console.log("Servidor rodando na porta 3000");
});