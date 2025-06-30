#!/bin/bash

echo "--- Tabla de Multiplicar del 5 ---"

for i in {1..10}
do
  let producto=5*i
  echo "5 x $i = $producto"
done