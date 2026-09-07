import express from 'express';
import path from 'path';

const app = express();

app.use(express.json());

app.get('api/login', (req,res) =>{
    res.status(200).json({
        sucess: true,
        message: 'WOW'
    })
})

app.listen(3000,'0.0.0.0',() =>{
    console.log(`Rodando na porta ${3000}`)
})