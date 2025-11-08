# 🖥️ Máquina Virtual v3 - Windows RDP Gratis

<div align="center">

![GitHub Stars](https://img.shields.io/github/stars/jephersonRD?style=social)
![GitHub Followers](https://img.shields.io/github/followers/jephersonRD?style=social)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux-lightgrey)

**¡Accede a una máquina virtual Windows completamente GRATIS usando GitHub Actions y Tailscale!**

[🌟 Sígueme en GitHub](https://github.com/jephersonRD) • [📺 Video Tutorial](#-video-tutorial) • [❓ Preguntas Frecuentes](#-preguntas-frecuentes)

# 🌟 ¡Apóyame con una ⭐ para seguir actualizando y mejorando este proyecto!

</div>

---

## 📋 Tabla de Contenidos

- [¿Qué es esto?](#-qué-es-esto)
- [Pasos para Tener la Máquina Virtual](#-pasos-para-tener-la-máquina-virtual-gratis)
- [Preguntas Frecuentes](#-preguntas-frecuentes)
- [Solución de Problemas](#-solución-de-problemas)
- [Contribuir](#-contribuir)

---

## 🎯 ¿Qué es esto?

Este repositorio te permite crear y acceder a una **máquina virtual Windows** completamente gratis usando GitHub Actions. La VM se ejecuta en los servidores de GitHub y puedes conectarte a ella mediante **RDP (Remote Desktop Protocol)** a través de una red privada segura con **Tailscale**.

### ✨ Características

- 🆓 **100% Gratis** - Usa los recursos de GitHub Actions
- 🔒 **Seguro** - Conexión encriptada mediante Tailscale
- ⚡ **Rápido** - Configura tu VM en minutos
- 💻 **Windows** - Sistema operativo Windows Server
- ⏱️ **Hasta 6 horas** - De uso continuo por sesión

---

## 📦 Requisitos Previos

Antes de comenzar, asegúrate de tener lo siguiente:

### 1️⃣ Cuenta de GitHub
- **¡Sígueme!** → [@jephersonRD](https://github.com/jephersonRD) 🌟

### 2️⃣ Tailscale
- Descarga e instala [Tailscale](https://tailscale.com/download)
- Crea una cuenta vinculada a tu cuenta de GitHub
- Genera un **Auth Key** desde [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)

### 3️⃣ Cliente RDP

| Sistema Operativo | Cliente RDP |
|-------------------|-------------|
| 🪟 **Windows** | Ya incluido por defecto (`mstsc.exe`) |
| 🐧 **Linux** | Instala `xrdp`: `sudo apt install xrdp` |
| 🍎 **macOS** | Descarga [Microsoft Remote Desktop](https://apps.apple.com/app/microsoft-remote-desktop/id1295203466) |

---

## 🚀 Pasos para Tener la Máquina Virtual Gratis

### 1️⃣ Seguir mi cuenta de GitHub

<div align="center">

**👉 [@jephersonRD](https://github.com/jephersonRD) 👈**

</div>

### 2️⃣ Tener Tailscale instalado con una cuenta vinculada a GitHub

- Descarga [Tailscale](https://tailscale.com/download)
- Vincula tu cuenta con GitHub

### 3️⃣ Tener RDP

- **Windows**: Ya lo tienes por defecto
- **Linux**: Usa `xrdp`

### 4️⃣ Copiar este código

```yaml
name: RDP

on:
  workflow_dispatch:

jobs:
  secure-rdp:
    runs-on: windows-latest
    timeout-minutes: 3600

    steps:
      - name: Configure Core RDP Settings
        run: |
          # Enable Remote Desktop and disable Network Level Authentication (if needed)
          Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' `
                             -Name "fDenyTSConnections" -Value 0 -Force
          Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' `
                             -Name "UserAuthentication" -Value 0 -Force
          Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' `
                             -Name "SecurityLayer" -Value 0 -Force

          # Remove any existing rule with the same name to avoid duplication
          netsh advfirewall firewall delete rule name="RDP-Tailscale"
         
          # For testing, allow any incoming connection on port 3389
          netsh advfirewall firewall add rule name="RDP-Tailscale" `
            dir=in action=allow protocol=TCP localport=3389

          # (Optional) Restart the Remote Desktop service to ensure changes take effect
          Restart-Service -Name TermService -Force

      - name: Create RDP User with Secure Password
        run: |
          Add-Type -AssemblyName System.Security
          $charSet = @{
              Upper   = [char[]](65..90)      # A-Z
              Lower   = [char[]](97..122)     # a-z
              Number  = [char[]](48..57)      # 0-9
              Special = ([char[]](33..47) + [char[]](58..64) +
                         [char[]](91..96) + [char[]](123..126)) # Special characters
          }
          $rawPassword = @()
          $rawPassword += $charSet.Upper | Get-Random -Count 4
          $rawPassword += $charSet.Lower | Get-Random -Count 4
          $rawPassword += $charSet.Number | Get-Random -Count 4
          $rawPassword += $charSet.Special | Get-Random -Count 4
          $password = -join ($rawPassword | Sort-Object { Get-Random })
          $securePass = ConvertTo-SecureString $password -AsPlainText -Force
          New-LocalUser -Name "RDP" -Password $securePass -AccountNeverExpires
          Add-LocalGroupMember -Group "Administrators" -Member "RDP"
          Add-LocalGroupMember -Group "Remote Desktop Users" -Member "RDP"
         
          echo "RDP_CREDS=User: RDP | Password: $password" >> $env:GITHUB_ENV
         
          if (-not (Get-LocalUser -Name "RDP")) {
              Write-Error "User creation failed"
              exit 1
          }

      - name: Install Tailscale
        run: |
          $tsUrl = "https://pkgs.tailscale.com/stable/tailscale-setup-1.82.0-amd64.msi"
          $installerPath = "$env:TEMP\tailscale.msi"
         
          Invoke-WebRequest -Uri $tsUrl -OutFile $installerPath
          Start-Process msiexec.exe -ArgumentList "/i", "`"$installerPath`"", "/quiet", "/norestart" -Wait
          Remove-Item $installerPath -Force

      - name: Establish Tailscale Connection
        run: |
          # Bring up Tailscale with the provided auth key and set a unique hostname
          & "$env:ProgramFiles\Tailscale\tailscale.exe" up --authkey=${{ secrets.TAILSCALE_AUTH_KEY }} --hostname=gh-runner-$env:GITHUB_RUN_ID
         
          # Wait for Tailscale to assign an IP
          $tsIP = $null
          $retries = 0
          while (-not $tsIP -and $retries -lt 10) {
              $tsIP = & "$env:ProgramFiles\Tailscale\tailscale.exe" ip -4
              Start-Sleep -Seconds 5
              $retries++
          }
         
          if (-not $tsIP) {
              Write-Error "Tailscale IP not assigned. Exiting."
              exit 1
          }
          echo "TAILSCALE_IP=$tsIP" >> $env:GITHUB_ENV
     
      - name: Verify RDP Accessibility
        run: |
          Write-Host "Tailscale IP: $env:TAILSCALE_IP"
         
          # Test connectivity using Test-NetConnection against the Tailscale IP on port 3389
          $testResult = Test-NetConnection -ComputerName $env:TAILSCALE_IP -Port 3389
          if (-not $testResult.TcpTestSucceeded) {
              Write-Error "TCP connection to RDP port 3389 failed"
              exit 1
          }
          Write-Host "TCP connectivity successful!"

      - name: Maintain Connection
        run: |
          Write-Host "`n=== RDP ACCESS ==="
          Write-Host "Address: $env:TAILSCALE_IP"
          Write-Host "Username: RDP"
          Write-Host "Password: $(echo $env:RDP_CREDS)"
          Write-Host "==================`n"
         
          # Keep runner active indefinitely (or until manually cancelled)
          while ($true) {
              Write-Host "[$(Get-Date)] RDP Active - Use Ctrl+C in workflow to terminate"
              Start-Sleep -Seconds 300
          }
```

## 🎥 Video Tutorial

<div align="center">

<a href="https://www.youtube.com/watch?v=6KDdo7-oPvY" target="_blank">
  <img src="https://img.youtube.com/vi/6KDdo7-oPvY/maxresdefault.jpg" 
       alt="Ver el video tutorial en YouTube" width="70%">
</a>

<br><br>

**🎬 Haz clic en la imagen para ver el tutorial completo en YouTube**

</div>
---

## ❓ Preguntas Frecuentes

<details>
<summary><b>¿Cuánto tiempo puedo usar la VM?</b></summary>

Cada sesión dura hasta 6 horas (3600 minutos). Después deberás ejecutar el workflow nuevamente.

</details>

<details>
<summary><b>¿Es realmente gratis?</b></summary>

Sí, GitHub Actions ofrece minutos gratuitos mensuales. Las cuentas gratuitas tienen 2000 minutos/mes.

</details>

<details>
<summary><b>¿Puedo instalar software en la VM?</b></summary>

Sí, tienes acceso de administrador. Puedes instalar cualquier software compatible con Windows.

</details>

<details>
<summary><b>¿Los archivos se guardan?</b></summary>

No, cuando finaliza el workflow, todos los datos se eliminan. Es una VM temporal.

</details>

<details>
<summary><b>¿Puedo usar esto para juegos?</b></summary>

Técnicamente sí, pero el rendimiento puede no ser óptimo ya que no está diseñado para gaming.

</details>

---

## 🔧 Solución de Problemas

### Error: "Tailscale IP not assigned"
- Verifica que tu Auth Key de Tailscale sea válido
- Asegúrate de que Tailscale esté activo en tu dispositivo

### No puedo conectarme por RDP
- Verifica que Tailscale esté conectado en tu PC
- Comprueba que copiaste correctamente la IP y contraseña
- Intenta reiniciar Tailscale

### El workflow se detiene automáticamente
- GitHub Actions tiene un límite de 6 horas por workflow
- Simplemente vuelve a ejecutar el workflow

---

## 🤝 Contribuir

¿Tienes ideas para mejorar este proyecto? ¡Las contribuciones son bienvenidas!

1. Haz un Fork del proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Consulta el archivo `LICENSE` para más detalles.

---

## 💖 Apoyo

Si este proyecto te ha sido útil, considera:

- ⭐ Darle una estrella a este repositorio
- 🐦 Seguirme en GitHub: [@jephersonRD](https://github.com/jephersonRD)
- 📺 Suscribirte a mi canal de YouTube
- ☕ Invitarme un café (si tienes un link de donación)

---

<div align="center">

**Hecho con ❤️ por [JephersonRD](https://github.com/jephersonRD)**

⭐ ¡No olvides darle una estrella al repo! ⭐

</div>
