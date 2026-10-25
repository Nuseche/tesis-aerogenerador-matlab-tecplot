# Casos reproducibles

- `config_stationary_modal.m`: modal conservativo a rotor detenido.
- `config_rotating_campbell.m`: continuación 0/6/12 RPM, QEP y MBC.
- `config_seismic_demo.m`: aceleración de base sintética y Newmark.
- `config_flexible_foundation.m`: matrices `Mf/Kf/Cf` del caso blando legado.

Los tres casos usan una rigidez de tren de potencia **ilustrativa**, declarada
en la configuración, porque los archivos heredados solo aportan una
penalización rígida y no una tangente física verificable. Los valores deben
reemplazarse por rigideces identificadas antes de interpretar los resultados
como predicción de la turbina. El solver nunca activa esos valores en
`config_default.m`; por eso la ejecución predeterminada es de geometría y
validación.

Ejemplo:

```matlab
results = main("cases/config_stationary_modal.m");
```
