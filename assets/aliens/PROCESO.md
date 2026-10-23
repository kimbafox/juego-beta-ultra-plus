# Assets de los protagonistas

- `alien_verde.png`: adaptación del dibujo verde aportado por el usuario.
- `alien_naranja.png`: adaptación del dibujo naranja aportado por el usuario, sin la lanza para permitir el uso de la pistola.

Preparados con la herramienta integrada de generación/edición de imágenes, a partir de las dos referencias. PNG de 1024 × 1536 con canal alfa. Los archivos originales del usuario no se modificaron.

Prompt base utilizado para cada imagen:

> Use case: background-extraction. Asset type: transparent PNG protagonist sprite for a 2D point-and-click game. Edit the supplied alien illustration into a clean standalone full-body character asset. Preserve this exact alien's identity, anatomy, distinctive head and eyes, original colors, rough hand-drawn black outlines and original illustration style. Remove the white background entirely; true transparent alpha, no ground shadow, no text or framing. Entire alien including feet and head visible, centered with small transparent padding.

Indicación adicional para el verde:

> Preserve its green body, large oval head and patterned white eyes.

Indicación adicional para el naranja:

> Remove only the long spear from the hand so the alien has an empty relaxed hand for gameplay. Preserve its orange body, eye stalks and claw feet.

Los dos PNG se utilizan en la presentación, en las tarjetas de selección y en el Sprite2D del protagonista. La altura lógica de juego se configura con `HEIGHT` en `scripts/actor.gd`.

## Hojas de animación aportadas
Se incluyen intactas las cuatro hojas PNG de caminar y disparar del usuario. AtlasTexture selecciona sus fotogramas sin modificar los originales. Los personajes miden 285 píxeles visibles y se anclan al suelo. El alien naranja conserva la lanza de su hoja de caminata y cambia a la pistola al equipar el arma.
