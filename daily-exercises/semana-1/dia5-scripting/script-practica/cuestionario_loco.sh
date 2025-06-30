#!/bin/bash

echo "🎉 ¡Bienvenido al Cuestionario Loco de DevOps! 🎉"
echo "-------------------------------------------------"

read -p "Primero, ¿cómo te llamás? " NOMBRE
read -p "¡Buena, $NOMBRE! Ahora decime tu edad: " EDAD
read -p "Y por último, ¿cuál es tu color favorito? (rojo/azul/verde) " COLOR

echo "-------------------------------------------------"
echo "🚀 Analizando tu perfil de DevOps..."
sleep 2 # Una pequeña pausa dramática

# Mensaje personalizado basado en la edad
if [ "$EDAD" -lt "25" ]; then
  MENSAJE_EDAD="¡Sos un joven padawan de DevOps! ¡La Fuerza es intensa en vos!"
else
  MENSAJE_EDAD="¡Sos un Maestro Jedi de la automatización! ¡Con gran poder viene gran responsabilidad!"
fi

# Mensaje personalizado basado en el color usando 'case'
case ${COLOR,,} in # ${COLOR,,} convierte la respuesta a minúsculas
  "rojo")
    MENSAJE_COLOR="Elegiste el rojo, Tienes fuego como Roxs🔥"
    ;;
  "azul")
    MENSAJE_COLOR="El azul, como los contenedores de Docker flotando en un mar de eficiencia. 💧"
    ;;
  "verde")
    MENSAJE_COLOR="Verde, como los builds que pasan todas las pruebas y se van a producción. ✅"
    ;;
  *) # El asterisco captura cualquier otra respuesta
    MENSAJE_COLOR="Elegiste un color misterioso... ¡como un bug en producción un viernes a la tarde! 👻"
    ;;
esac

echo "Okay, $NOMBRE, acá está tu diagnóstico:"
echo "$MENSAJE_EDAD"
echo "$MENSAJE_COLOR"
echo "💥 ¡A seguir rompiéndola! 💥"