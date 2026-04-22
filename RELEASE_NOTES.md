# Payly — Release Notes

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

- Animaciones y transiciones de UI optimizadas
- Splash screen diseñado en Figma
- Optimizaciones de rendimiento generales
- Experiencia de usuario refinada y pulida
