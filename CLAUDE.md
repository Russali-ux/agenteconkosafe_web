# agenteconkosafe_web

Automatización del llenado del formulario de reporte de reacciones
adversas en https://soltonpharma.com/farmacovigilancia/ usando agent-browser.

## Browser Automation

Usa `agent-browser` para automatizar navegador. Corre `agent-browser --help` para ver todos los comandos.

Flujo base:
1. `agent-browser open <url>` — navegar
2. `agent-browser snapshot -i` — obtener elementos interactivos con refs (@e1, @e2)
3. `agent-browser click @e1` / `agent-browser fill @e2 "texto"` — interactuar
4. Volver a hacer snapshot después de cualquier cambio en la página
