# Dirección de arte y assets

Se crearon seis imágenes con la herramienta integrada de generación de imágenes, para sustituir los decorados geométricos y el menú anteriores. El estilo es terror ambiental clásico: paredes envejecidas, luz práctica tenue, tonos oliva, sepia y carbón. No se utilizaron logos ni recursos extraídos de Resident Evil.

## Prompts de producción

Para las cuatro habitaciones se utilizó esta base:

> Original 2D point-and-click survival horror game background, inspired by late-1990s pre-rendered survival horror atmosphere. Wide 16:9 landscape image. Straight-on side view of ONE room, fixed camera, NOT a corridor vanishing point. Realistically painted textured illustration, muted olive gray and dirty warm beige, worn plaster, gritty atmospheric shadows, restrained practical lighting, readable objects, eerie abandoned research facility. No people, no aliens, no HUD, no text, no logos, no blood. Entire rear wall visible, wall-floor boundary at 82 percent image height, shallow empty walkable floor across bottom 18 percent. Objects must be well-separated and unobscured.

Se añadieron instrucciones de composición distintas:

- **lobby.png:** abrigo colgado a la izquierda; papel en un tablón en el centro; armario metálico de suministros a la derecha, luz de escritorio cálida y fluorescente frío.
- **archive.png:** estantería de madera con carpetas a la izquierda; caja fuerte metálica independiente a la derecha, iluminada por una lámpara colgante.
- **workshop.png:** tablero eléctrico abierto a la izquierda; instrucciones en papel en el centro; vitrina de seguridad vacía a la derecha. La tarjeta se coloca en Godot para poder retirarla cuando se recoge.
- **control.png:** lector de tarjeta a la izquierda; consola con tres indicadores en el centro; puerta de salida de acero a la derecha.

Prompt del menú:

> Original survival horror video game title-screen background. Wide 16:9 cinematic composition. An abandoned decaying medical research facility, distant steel doorway on the RIGHT third ajar with a thin ominous deep crimson light spilling out, wet cracked concrete, dust and subtle fog, scratched charcoal walls, subtle film grain. The LEFT half is mostly nearly black negative space, softly textured, reserved for title and menu that will be added in engine. Sophisticated understated eerie atmosphere, muted sepia gray and black with small deep red accent, realistic painted concept art with beautiful lighting. NO text, NO logo, NO people, NO UI. Inspired by classic 1990s survival horror atmosphere, original scene.

Prompt de objetos:

> Game inventory icon atlas, transparent background, exactly 3 columns by 2 rows, six equal square cells, evenly spaced centers, each object isolated within its own cell, generous padding no object crosses cells. Top row from left to right: an old olive green ammunition carton with a few brass bullets; a small antique brass key; a ceramic cylindrical electrical fuse. Bottom row left to right: a worn ivory security access card with dark stripe and no readable text; a compact dark steel handgun side profile; an old leather notebook. Realistic hand-painted survival horror inventory objects, detailed worn textures, restrained colors, overhead soft studio lighting, clean readable silhouettes. No words, no frames, no grid lines, no drop shadows outside objects. Landscape 3:2 composition, all six cells identical dimensions.

Los textos, las zonas de clic, los estados de los puzles, la mira y la interfaz se dibujan en Godot sobre estas imágenes. Las fuentes se incluyen en `assets/` con su licencia.
