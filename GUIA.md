# 📘 Guía de mi sitio web

Todo lo que necesito para entender y actualizar mi página
**https://joaquinvapasten.github.io/**

---

## 1. ¿Cómo funciona, en una frase?

Escribo en archivos `.qmd` (texto sencillo) → los subo a GitHub → un robot
(GitHub Actions) **convierte ese texto en una página web** y la publica sola.

No edito HTML ni toco el diseño: solo cambio texto y subo. El robot hace el resto.

```
Edito un .qmd  →  git push  →  GitHub Actions renderiza  →  sitio actualizado
   (yo)            (yo)          (automático)                (automático)
```

---

## 2. ¿Qué es cada archivo?

| Archivo / carpeta | Qué es | ¿Lo toco? |
|---|---|---|
| `index.qmd` | La portada ("Sobre mí", líneas de interés) | ✅ Sí |
| `cv.qmd` | Página del CV (muestra el PDF) | ✅ Sí, poco |
| `visualizadores.qmd` | Galería de tus visualizadores en R | ✅ Sí |
| `lecturas.qmd` | Página de lecturas/biblioteca | ✅ Sí |
| `files/cv.pdf` | Tu CV en PDF (lo que se descarga) | ✅ Reemplazar |
| `img/perfil.jpg` | Tu foto de perfil | ✅ Reemplazar |
| `proyectos/*.qmd` | Cada visualizador con código R | ✅ Avanzado |
| `_quarto.yml` | Configuración: menú, título, links, correo | ⚠️ Con cuidado |
| `custom.scss` | Los colores y el diseño (tema oscuro) | ⚠️ Solo si quieres |
| `styles.css` | Ajustes extra de estilo | ⚠️ Rara vez |
| `.github/workflows/publish.yml` | El "robot" que publica | ❌ No tocar |
| `GUIA.md` | Esta guía | — |

> **Regla de oro:** si solo quieres cambiar **texto**, edita los `.qmd`. Nada más.

---

## 3. La sintaxis que uso en los `.qmd` (Markdown)

Es texto normal con marquitas:

```markdown
## Título de sección          ← un encabezado
### Subtítulo

Texto normal en un párrafo.

**negrita**  y  *cursiva*

- lista
- de cosas

[texto del link](https://ejemplo.com)     ← un enlace
![](img/perfil.jpg)                        ← una imagen
```

Cada página empieza con un bloque entre `---` (se llama *front matter*); ahí va el
título de la página. **No lo borres**, solo edita lo de adentro si hace falta:

```yaml
---
title: "Curriculum Vitae"
---
```

---

## 4. Las 3 tareas más comunes

### ✏️ A) Cambiar un texto (lo más frecuente)
1. Abre el `.qmd` que toque (ej. `index.qmd`) en cualquier editor de texto.
2. Cambia lo que quieras.
3. Guarda y **publica** (ver sección 5).

### 🖼️ B) Cambiar mi foto
1. Guarda tu foto nueva como `perfil.jpg` (mismo nombre) dentro de la carpeta `img/`,
   reemplazando la anterior.
2. Publica. *(Tip: que sea cuadrada, ~600×600 px, para que se vea bien.)*

### 📄 C) Actualizar mi CV
1. Reemplaza `files/cv.pdf` por tu CV nuevo (mismo nombre `cv.pdf`).
2. Publica. La página del CV se actualiza sola.

---

## 5. Cómo publicar los cambios (2 opciones)

### Opción 1 — Desde la web de GitHub (la más fácil, sin instalar nada)
1. Entra a tu repo: https://github.com/joaquinvapasten/joaquinvapasten.github.io
2. Abre el archivo que quieres editar y haz clic en el lápiz ✏️ (arriba a la derecha).
3. Edita, baja y pulsa **"Commit changes"** (verde).
4. ¡Listo! El robot publica solo en unos minutos.

> Para cambiar la **foto** o el **CV** por la web: entra a la carpeta (`img/` o `files/`),
> usa **"Add file → Upload files"** y sube el archivo con el **mismo nombre** para reemplazarlo.

### Opción 2 — Desde tu computador (con Git)
Abre una terminal en la carpeta del proyecto y corre, cada vez que cambies algo:

```bash
git add .
git commit -m "Actualizo tal cosa"
git push
```

Con eso se dispara la publicación automática.

---

## 6. ⏱️ ¿Cuánto se demora en verse el cambio?

Cuando subes algo, pasan dos cosas en cadena:

1. **GitHub Actions renderiza** (instala R, arma las páginas, publica) → **~2 a 4 min**
   la mayoría de las veces. *(La primera vez fue más lenta porque instaló todo de cero.)*
2. **GitHub Pages sirve la página** → **~30 seg a 1 min** extra.

➡️ **En total: normalmente 3–5 minutos** desde que haces *push* hasta que se ve online.

Trucos:
- Si recargas y no ves el cambio, prueba **Ctrl + F5** (recarga sin caché) o abre en
  ventana de incógnito — a veces es solo el caché del navegador.
- Puedes ver el progreso en la pestaña **"Actions"** de tu repo: un ✓ verde = publicado,
  un punto amarillo = en proceso, una ✗ roja = falló (ahí dice por qué).

---

## 7. (Opcional) Previsualizar ANTES de publicar

Si quieres ver los cambios en tu computador antes de subirlos, instala
[Quarto](https://quarto.org) (ya lo tienes ✅) y corre en la carpeta:

```bash
quarto preview
```

Se abre en el navegador y se **recarga solo** cada vez que guardas. Para cerrarlo: `Ctrl + C`.

> ⚠️ Las páginas con código **R** (los visualizadores) solo se previsualizan en local si
> tienes **R instalado**. Si no, no te preocupes: el robot de GitHub sí tiene R y las arma
> igual al publicar. Las páginas de solo texto (portada, CV, lecturas) se ven sin R.

---

## 8. Agregar un visualizador nuevo (avanzado, con R)

1. Copia `proyectos/ejemplo-desigualdad.qmd` y renómbralo, ej. `proyectos/casen.qmd`.
2. Dentro, reemplaza los datos de ejemplo por los tuyos y tu código R (va en bloques
   ` ```{r} ... ``` `).
3. En `visualizadores.qmd`, agrega una tarjeta que apunte a `proyectos/casen.html`.
4. Publica. El robot ejecuta tu R y genera la página interactiva.

---

## 9. Cosas que conviene NO romper

- No borres los bloques `---` del inicio de cada `.qmd`.
- No cambies el nombre de `index.qmd` (es la portada obligatoria).
- No edites `.github/workflows/publish.yml` salvo que sepas lo que haces.
- Mantén los nombres `perfil.jpg` y `cv.pdf` al reemplazarlos (así no hay que tocar código).
- Si algo se rompe, en **Actions** verás el error; y siempre puedes volver atrás con el
  historial de commits de GitHub.

---

## 10. Mis enlaces

- 🌐 Sitio: https://joaquinvapasten.github.io/
- 📦 Repo (código): https://github.com/joaquinvapasten/joaquinvapasten.github.io
- 🔧 Estado de publicaciones: pestaña **Actions** del repo
- 📚 Documentación de Quarto: https://quarto.org/docs/websites/
