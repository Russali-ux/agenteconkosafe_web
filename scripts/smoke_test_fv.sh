#!/usr/bin/env bash
set -euo pipefail

URL="https://soltonpharma.com/farmacovigilancia/"
FECHA=$(TZ="America/Lima" date +"%Y-%m-%d_%H-%M")
MES_DIR=$(TZ="America/Lima" date +"%Y-%m")
PROJECT_DIR="$(pwd -W 2>/dev/null || pwd)"
EVIDENCIA_DIR="evidencia/$MES_DIR"
mkdir -p "$EVIDENCIA_DIR"

LOG_FILE="$EVIDENCIA_DIR/smoke-test-$FECHA.log"
ANTES="$PROJECT_DIR/evidencia/$MES_DIR/antes-envio-$FECHA.png"
DESPUES="$PROJECT_DIR/evidencia/$MES_DIR/despues-envio-$FECHA.png"

echo "=== Smoke test FV — $FECHA (hora Lima) ===" | tee "$LOG_FILE"

agent-browser open "$URL"

SNAPSHOT=$(agent-browser snapshot -i)
echo "$SNAPSHOT" >> "$LOG_FILE"

get_date_refs() {
  local anchor="$1"
  echo "$SNAPSHOT" | awk -v anchor="$anchor" '
    index($0, anchor) > 0 { print day; print mon; print yr; exit }
    /spinbutton "Día/ { day = $0 }
    /spinbutton "Mes/ { mon = $0 }
    /spinbutton "Año/ { yr  = $0 }
  '
}
extract_ref() { echo "$1" | grep -oE 'ref=e[0-9]+' | grep -oE '[0-9]+'; }

ADMIN_LINES=$(get_date_refs "Fecha de inicio de la administración")
EVENTO_LINES=$(get_date_refs "Fecha de inicio del evento")

ADMIN_DIA=$(extract_ref "$(echo "$ADMIN_LINES" | sed -n '1p')")
ADMIN_MES=$(extract_ref "$(echo "$ADMIN_LINES" | sed -n '2p')")
ADMIN_ANIO=$(extract_ref "$(echo "$ADMIN_LINES" | sed -n '3p')")

EVENTO_DIA=$(extract_ref "$(echo "$EVENTO_LINES" | sed -n '1p')")
EVENTO_MES=$(extract_ref "$(echo "$EVENTO_LINES" | sed -n '2p')")
EVENTO_ANIO=$(extract_ref "$(echo "$EVENTO_LINES" | sed -n '3p')")

DIA=$(TZ="America/Lima" date +"%d")
MES_NUM=$(TZ="America/Lima" date +"%m")
ANIO=$(TZ="America/Lima" date +"%Y")

agent-browser find label "Escribe tus nombres *" fill "PRUEBA-AUTOMATIZADA"
agent-browser find label "Escribe tus apellidos *" fill "QA-SMOKE-TEST"
agent-browser find label "Coloca tu e - mail *" fill "vigilanciasanitaria@soltonpharma.com"
agent-browser find label "Nombre del paciente *" fill "PACIENTE-PRUEBA"
agent-browser find label "Apellidos del paciente *" fill "NO-ES-CASO-REAL"
agent-browser find label "Teléfono de contacto *" fill "987495573"
agent-browser find label "Edad *" fill "30"
agent-browser find label "Nombre del medicamento *" fill "PRODUCTO-PRUEBA-QA"
agent-browser find label "Descripción del evento adverso *" \
  fill "CASO DE PRUEBA generado automáticamente por el smoke test mensual de QA (agenteconkosafe_web). NO corresponde a un evento adverso real. Favor descartar."

agent-browser fill "@e${ADMIN_DIA}" "$DIA"
agent-browser fill "@e${ADMIN_MES}" "$MES_NUM"
agent-browser fill "@e${ADMIN_ANIO}" "$ANIO"
agent-browser fill "@e${EVENTO_DIA}" "$DIA"
agent-browser fill "@e${EVENTO_MES}" "$MES_NUM"
agent-browser fill "@e${EVENTO_ANIO}" "$ANIO"

agent-browser find label "Estoy de acuerdo" check 2>/dev/null || true

agent-browser screenshot "$ANTES"

agent-browser find role button click --name "Enviar"
agent-browser wait --load networkidle
agent-browser screenshot "$DESPUES"

PAGE_TEXT=$(agent-browser get text body)

if echo "$PAGE_TEXT" | grep -qi "gracias"; then
  echo "RESULTADO: OK - formulario enviado y confirmado" | tee -a "$LOG_FILE"
  echo "status=OK" >> "${GITHUB_OUTPUT:-/dev/null}"
elif echo "$PAGE_TEXT" | grep -qi "tienen un error"; then
  echo "RESULTADO: FALLO - error de validación en el formulario" | tee -a "$LOG_FILE"
  echo "status=FALLO" >> "${GITHUB_OUTPUT:-/dev/null}"
  agent-browser close
  exit 1
else
  echo "RESULTADO: FALLO - no se detectó ni éxito ni error conocido" | tee -a "$LOG_FILE"
  echo "status=FALLO" >> "${GITHUB_OUTPUT:-/dev/null}"
  agent-browser close
  exit 1
fi

agent-browser close
