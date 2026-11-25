# Bitácora Trimoto TC2-160

Página web para llevar el **parte diario** de la trimoto eléctrica GreenLine TC2-160: quién la usa cada día, el estado de la batería, la carga transportada, las revisiones, las fallas y los mantenimientos pendientes.

**Página en línea:** https://jair40398.github.io/bitacora-trimoto/

## Qué hace

- **Parte diario:** operador, fecha, hora de salida y retorno, batería % de salida y retorno, carga en kg, destino, revisión de frenos, luces y llantas, si cargó la batería y observaciones.
- **Alertas en cada registro:** carga mayor a 500 kg (máximo del manual), batería de retorno menor a 20 % o una revisión sin marcar.
- **Mapa de fallas:** dibujo de la trimoto con un punto por sistema (batería, motor, frenos, controlador, cableado, luces, llantas, chasis). Rojo si hay fallas pendientes. Al tocar un punto se filtra la lista.
- **Mantenimiento:** avisos de calibración de llantas (cada mes, 42 PSI delantera y 45 PSI posterior) y de carga de batería (al menos una vez por semana), según el manual del fabricante.
- **Historial** con filtro por operador, resumen y descarga en CSV.

## Cómo funciona

| Parte | Tecnología |
|---|---|
| Página | Un solo archivo `index.html` (HTML, CSS y JavaScript, sin librerías), publicado con GitHub Pages |
| Datos | [Supabase](https://supabase.com) (Postgres, código abierto), plan gratuito |

- **Leer:** cualquiera con el enlace puede ver los datos.
- **Escribir** (guardar, marcar una falla como resuelta, borrar): hace falta la **clave de escritura**. Esa clave no está en el código; la verifica la base de datos mediante funciones, y sin la clave correcta se rechaza la operación.
- La página se actualiza sola cada 30 segundos.

## Usarla

1. Abre el enlace de la página.
2. Escribe la clave de escritura en la primera tarjeta (el navegador la recuerda en ese equipo).
3. Registra el parte, reporta fallas o anota los mantenimientos.

Los datos se pueden descargar con **Descargar CSV** en el historial. Conviene hacerlo de vez en cuando como respaldo, porque el plan gratuito de Supabase no incluye copias automáticas.

## Montarla desde cero

1. Crea un proyecto en Supabase.
2. Abre `supabase_setup.example.sql`, cambia `CAMBIA-ESTA-CLAVE` por tu clave de escritura (8 o más caracteres) y ejecútalo completo en **SQL Editor > Run**. No guardes tu clave real en este repositorio.
3. En Supabase, en **Project Settings > API**, copia la **URL del proyecto** y la **clave pública** (publishable o anon). No uses la clave secret ni la service_role.
4. En `index.html`, busca la línea `var CFG=` y pega ambos datos entre comillas.
5. Sube `index.html` a un repositorio público de GitHub y activa **Settings > Pages**, con *Deploy from a branch*, rama `main` y carpeta `/ (root)`.

Para cambiar la clave de escritura, vuelve a ejecutar solo el último bloque del script con la clave nueva.

## Limitaciones conocidas

- Hay **una sola clave** para todos los operadores. No se sabe quién escribió algo más allá del nombre que cada uno teclea, y quien tenga la clave puede borrar registros.
- Los registros de mantenimiento no se pueden borrar desde la página, solo desde Supabase.
- En el plan gratuito, Supabase pausa el proyecto si pasa una semana sin actividad. Con uso diario no debería ocurrir; si pasa, se reactiva desde su panel.

## Fuente de los plazos y límites

Carga máxima, presión de llantas, carga semanal de la batería y calibración mensual salen del *Manual de uso TC2-160* de GreenLine (14/07/2025).
