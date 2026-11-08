# instalar-apps-ventura

Script para dejar lista una Mac Intel con **macOS Ventura (13)** recién instalado: instala las apps de una sola corrida, sin compilar nada y con la última versión de cada una que todavía corre en Ventura.

## Uso

En la Terminal, con tu usuario (sin `sudo`) y con internet:

```bash
curl -fsSLO https://raw.githubusercontent.com/hazur84/instalar-apps-ventura/main/instalar_apps.sh
bash instalar_apps.sh
```

- Pide la contraseña de la Mac una vez; la Mac no se duerme mientras instala.
- `bash instalar_apps.sh lista` solo dice qué ya está y qué falta.
- Se puede volver a correr: salta lo instalado.
- Al final deja `Resultado-instalar-apps.txt` en el Escritorio, y el registro completo en `~/Library/Logs/instalar-apps-<fecha>.log`.
- Ocupa unos 40 GB libres. La primera vez, Homebrew y las Command Line Tools tardan de 10 a 20 minutos.

No lo corras con `curl … | bash`: el script hace preguntas y necesita la Terminal.

## Qué instala

| Cómo | Apps |
|---|---|
| Homebrew (lo instala si falta) | Adobe Creative Cloud, balenaEtcher, Brave, draw.io, Free Download Manager, FreeCAD, iStat Menus, Microsoft Edge, Word, Excel, PowerPoint, OmniGraffle, Proton Pass, Spotify, Sublime Text, Visual Studio Code, WhatsApp |
| Descarga directa, con versión fija y SHA-256 | AppCleaner 3.6.8, Rectangle 1.100, LyX 2.5.2, OCAuxiliaryTools |
| CTAN, verificado con SHA-512 | MacTeX completo (~7 GB) |
| App Store, desde «Comprado» | Keynote, Pages, Numbers, iMovie, IP Scanner |

Por qué así:

- Homebrew ya no da soporte oficial a Ventura en Intel. Los casks siguen funcionando (con avisos), pero las fórmulas se compilarían; por eso el script solo usa casks.
- Homebrew escoge solo la variante para Ventura: Office queda en la 16.101, la última para macOS 13.
- AppCleaner 3.7 pide macOS 15 y Rectangle 2.0 pide macOS 14; en Ventura van versiones fijas. En un macOS más nuevo, el script usa sus casks.
- Homebrew retiró LyX y OCAuxiliaryTools no está en Homebrew.
- El cask de MacTeX arrastra Ghostscript, que en Ventura se compilaría por horas; por eso va directo de CTAN.
- Las versiones actuales de las apps de Apple piden macOS 26. El script abre la App Store en «Comprado»: das clic en la nube de cada una y aceptas «la última versión compatible». Solo funciona con apps que ya están en tu cuenta.

## Cambiar la lista

Las listas están al principio del script. Un `#` al principio del renglón = no se instala. Ya vienen como opcionales, comentadas: Google Chrome, Google Drive, Adobe Acrobat, Outlook y extFS.

## Después de instalar

- Abre Word y entra con tu cuenta de Microsoft para activar Office; igual con Adobe Creative Cloud.
- Rectangle e iStat Menus piden permiso de Accesibilidad la primera vez.
- iStat Menus, OmniGraffle y Sublime Text piden su licencia.
- En LyX: Herramientas › Reconfigurar, para que encuentre MacTeX. Abre una Terminal nueva para usar los comandos de TeX.
