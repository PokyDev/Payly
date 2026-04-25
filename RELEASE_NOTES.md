# Payly — Release Notes

---

## v1.2.1 · 2026-04-25

> Parche de correcciones visuales y de estabilidad sobre v1.2.0.

### Correcciones

#### Splash nativo de Android 12+ (zoom sobre el ícono)
- En dispositivos con Android 12 o superior, el sistema mostraba automáticamente un zoom animado sobre el ícono del launcher antes de que Flutter cargara, lo que reducía la resolución visible del ícono y rompía la coherencia visual con el splash personalizado
- Se añadieron `values-v31/styles.xml` y `values-night-v31/styles.xml` que anulan el comportamiento por defecto de la SplashScreen API de Android 12+
- El splash nativo ahora muestra un fondo sólido `#141210` con un ícono del mismo color (invisible), haciendo la transición al `PaylyInitSplash` de Lottie completamente imperceptible

#### Re-render visible en `GenerateScreen` al completar el splash
- Al terminar la animación del splash, `AnimatedSwitcher` destruía y recreaba `HomeScreen` por el cambio de fase (`init` → `home`), lo que forzaba a `GenerateScreen` a ejecutar `initState()` de nuevo y recargar el borrador desde `SharedPreferences`
- El usuario veía un parpadeo momentáneo con la pantalla re-renderizándose y los datos del borrador reapareciendo
- Solución: el `PaylyInitSplash` ahora es un overlay en un `Stack` padre independiente del `AnimatedSwitcher`; las claves de navegación son semánticas (`'home'` / `'auth'`) y no cambian al completar el splash — Flutter preserva el estado de `HomeScreen` y `GenerateScreen` sin recrearlos

#### Re-renders espurios por eventos duplicados de Firebase Auth
- El listener `authStateChanges` podía emitir el mismo usuario varias veces (ej. al refrescar el token), cayendo en la rama `else` que llamaba `setState` incondicionalmente
- Añadida guardia `_user?.uid != user?.uid`: si el usuario no cambió, se omite el rebuild

---

## v1.2.0 · 2026-04-24

> Primera versión pública estable. Payly sale de fase alpha y está disponible al público.

### Novedades

#### Splash screen con animación personalizada
- Al abrir la app se reproduce una animación Lottie diseñada en Figma con identidad visual de Payly
- La animación se reproduce una sola vez; al finalizar, la pantalla espera 2 segundos y luego desaparece con un fade-out suave de 700 ms
- El contenido de la pantalla siguiente (inicio de sesión o pantalla principal) se precarga en segundo plano durante la pausa — no hay fondo negro entre la animación y la app
- La transición es completamente fluida: el fade del splash revela el contenido ya renderizado

### Cambios técnicos
- Nuevo widget `PaylyInitSplash` en `lib/widgets/payly_init_splash.dart` con lógica de ciclo de vida del splash desacoplada de `main.dart`
- Sincronización splash ↔ Firebase Auth: la app espera a que ambos estén listos antes de transitar (evita pantallas vacías o transiciones prematuras)
- Stack en `main.dart` que renderiza la pantalla destino detrás del splash en cuanto Firebase resuelve el estado de autenticación
- Paquete [`lottie ^3.3.1`](https://pub.dev/packages/lottie) integrado

---

## payly-alpha v1.2 · 2026-04-22

> Esta es una versión **pre-release** de fase alpha. No representa la versión final del producto.

### Novedades

#### Feedback visual al guardar un registro de pago
- El botón "Guardar registro de pago" ahora cambia de paleta al confirmar: transición animada de amarillo a verde con texto en blanco, indicando éxito de forma clara
- El cambio de color dura 5 segundos con transición suave (`easeInOut`) y fade en el texto
- Aparece un banner informativo debajo del botón con animación de deslizamiento desde arriba: _"Puedes revisar tus pagos registrados en el apartado de Historial"_ — desaparece automáticamente a los 5 segundos con animación inversa
- El banner respeta el tema claro y oscuro usando la paleta amber de la app

#### Splash de transición en detalle de pago
- Al actualizar la propina de un pago registrado, se muestra una pantalla de transición con el mensaje "Propina actualizada" y confirmación de sincronización en la nube
- Al eliminar un registro, se muestra una pantalla de transición con el mensaje "Registro eliminado"
- Ambas transiciones usan fade de 280ms y se cierran automáticamente a los 2 segundos

#### Widget reutilizable: `PaylyConfirmSheet`
- Nuevo widget genérico de confirmación tipo bottom sheet con animación de slide desde la parte inferior
- Configurable: título, cuerpo, etiqueta del botón de confirmación, color y callbacks
- Implementado en la confirmación de cierre de sesión en Ajustes, reemplazando la lógica inline anterior

### Mejoras de UX

- El teclado se descarta automáticamente al cambiar de pestaña en la barra de navegación inferior
- El teclado se descarta automáticamente al navegar hacia atrás desde la pantalla de detalle de pago
- Envolver `GenerateScreen` y `PaymentDetailScreen` en `GestureDetector` para cerrar el teclado al tocar fuera de los campos

### Correcciones

- Corregida importación faltante en `main.dart` que causaba error en tiempo de ejecución
- Corrección de estilos visuales en `payment_detail_screen.dart`
- Refactorización del modal de logout en `SettingsScreen`: el `AnimationController` ahora vive dentro del widget `PaylyConfirmSheet`, eliminando el `SingleTickerProviderStateMixin` de la pantalla padre

---

## payly-alpha v1.1 · 2026-04-22

> Esta es una versión **pre-release** de fase alpha. No representa la versión final del producto.

### Novedades

#### Registro de pagos semanales (funcionalidad principal)
- Registro completo de días laborados con hora de entrada y salida por día
- Cálculo automático de horas totales y valor a pagar según tarifa por hora configurada
- Campo de propina adicional (opcional) sumado al pago base
- Borrador persistente por usuario: el formulario se guarda localmente mientras no se confirme

#### Historial de pagos
- Visualización de todos los registros guardados en Firebase Firestore, sincronizados en la nube
- Detalle individual de cada registro: días laborados, horas, desglose de pago
- Edición de propina desde el detalle de cada pago
- Eliminación de registros con confirmación

#### Firebase / Firestore
- Estructura de datos por usuario: `users/{uid}/payments/{paymentId}`
- Creación automática del documento de perfil `users/{uid}` al registrarse o iniciar sesión con Google
- Stream en tiempo real del historial — los cambios se reflejan instantáneamente sin recargar

#### Autenticación
- Registro con correo, contraseña y nombre de usuario único
- Inicio de sesión con correo y contraseña
- Inicio de sesión con Google (Google Sign-In)
- Recuperación de contraseña por correo
- Verificación de disponibilidad de nombre de usuario en tiempo real

#### Ajustes
- Configuración de tarifa por hora (COP)
- Hora de entrada y salida predeterminada para nuevos registros
- Modo oscuro / claro
- Inicio de semana configurable

### Correcciones técnicas
- Corregido bug donde el historial mostraba indicador de carga en cada rebuild del árbol de widgets
- `HistoryScreen` convertida a `StatefulWidget` para mantener el stream de Firestore estable entre rebuilds
- `HomeScreen` mantiene la instancia de `HistoryScreen` como campo fijo, evitando recreación innecesaria

---

## payly-beta v1.1 (Pre-release anterior)

- Proyecto Flutter inicializado con Firebase (Android)
- Integración de `flutter_launcher_icons` para generación de íconos en todas las densidades
- Ícono personalizado de Payly aplicado a Android e iOS
- APK de prueba para validar apariencia del AppIcon en dispositivo real

---

## Roadmap — próximas versiones

- Sistema de notificaciones: recordatorios de registro de horas y avisos de pago
- Refinamiento y pulido de UX/UI en pantallas principales
- Optimizaciones de rendimiento generales
