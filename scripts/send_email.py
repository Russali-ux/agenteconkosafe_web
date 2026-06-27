import os, smtplib, glob
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.image import MIMEImage
from datetime import datetime
from zoneinfo import ZoneInfo

status = os.environ.get("STATUS", "DESCONOCIDO")
ahora = datetime.now(ZoneInfo("America/Lima"))
fecha = ahora.strftime("%Y-%m-%d %H:%M")
mes = ahora.strftime("%Y-%m")

msg = MIMEMultipart()
msg["Subject"] = f"[{status}] Smoke test mensual FV Solton - {fecha}"
msg["From"] = os.environ["SMTP_USER"]
msg["To"] = os.environ["NOTIFY_TO"]

msg.attach(MIMEText(f"""Resultado del smoke test automatizado del formulario de
farmacovigilancia de Solton Pharma (soltonpharma.com/farmacovigilancia/).

Estado: {status}
Fecha/hora (Lima): {fecha}

Este envío es una PRUEBA generada por QA (agenteconkosafe_web). No corresponde
a un caso real. Se adjuntan capturas de evidencia.
""", "plain"))

for img_path in sorted(glob.glob(f"evidencia/{mes}/*.png")):
    with open(img_path, "rb") as f:
        img = MIMEImage(f.read())
        img.add_header("Content-Disposition", "attachment", filename=os.path.basename(img_path))
        msg.attach(img)

with smtplib.SMTP(os.environ["SMTP_SERVER"], int(os.environ.get("SMTP_PORT", 587))) as s:
    s.starttls()
    s.login(os.environ["SMTP_USER"], os.environ["SMTP_PASS"])
    s.sendmail(msg["From"], [os.environ["NOTIFY_TO"]], msg.as_string())

print("Email enviado.")
