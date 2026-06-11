<?php

return [
    'entry_fee_brl' => (int) env('BOLAO_ENTRY_FEE_BRL', 50),

    /** Ordem fixa: índice 0 = primeiro da rotação semanal (ISO week % count). */
    'careca_emails' => [
        'limirio.neto@b2agencia.com.br',
        'guilherme.fernandes@b2agencia.com.br',
        'igor.fraga@b2agencia.com.br',
    ],
];
