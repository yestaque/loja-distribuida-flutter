const express = require("express");
const router = express.Router();

const mercadopago = require("../services/mercadoPago");

router.post("/criar", async (req, res) => {

  const { valor, email } = req.body;

  try {

    const payment = await mercadopago.payment.create({
      transaction_amount: valor,
      description: "Pedido Loja",
      payment_method_id: "pix",
      payer: {
        email: email
      }
    });

    res.json({
      id: payment.body.id,
      qr: payment.body.point_of_interaction.transaction_data.qr_code,
      qr_base64: payment.body.point_of_interaction.transaction_data.qr_code_base64
    });

  } catch (error) {
    res.status(500).json(error);
  }

});

router.get("/status/:id", async (req, res) => {

  const payment = await mercadopago.payment.findById(req.params.id);

  res.json({
    status: payment.body.status
  });

});

module.exports = router;