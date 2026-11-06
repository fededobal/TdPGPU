import os
import glob
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.widgets import Button

# Buscar los archivos generados
files = sorted(glob.glob("output_frames/iter_*.bin"))

if not files:
    print("No se encontraron archivos en 'output_frames/'")
    exit()

nfiles = len(files)

plt.rcParams['toolbar'] = 'None'

# Cargar los datos en memoria
frames_data = []
grid_size = 0

for file_path in files:
    with open(file_path, "rb") as f:
        grid_size = np.fromfile(f, dtype=np.int32, count=1)[0]
        grid_flat = np.fromfile(f, dtype=np.float32)
        grid_2d = grid_flat.reshape((grid_size, grid_size))
        frames_data.append(grid_2d)

# Clase para gestionar la animación
class AnimacionCalor:
    def __init__(self, frames, n):
        self.frames = frames
        self.nfiles = n
        
        # Configurar ventana y ejes (deja espacio abajo para el botón de volver a animar)
        self.fig, self.ax = plt.subplots(figsize=(6, 6))
        self.fig.subplots_adjust(bottom=0.2)
        
        self.im = self.ax.imshow(self.frames[0], cmap='jet', vmin=0, vmax=100, origin='lower')
        self.fig.colorbar(self.im, ax=self.ax, label="Temperatura (°C)")
        
        # Crear el botón en la interfaz gráfica
        ax_boton = self.fig.add_axes([0.35, 0.05, 0.3, 0.075])
        self.btn_reproducir = Button(ax_boton, 'Volver a animar', color='lightgoldenrodyellow', hovercolor='0.9')
        self.btn_reproducir.on_clicked(self.reiniciar_animacion)
        
        self.reproduciendo = False

    def reproducir(self):
        for i in range(self.nfiles):
            if plt.fignum_exists(self.fig.number) and self.reproduciendo:
                self.im.set_array(self.frames[i])
                self.ax.set_title(f"Simulación de Calor 2D - Iteración: {i} de {self.nfiles}")
                plt.draw()
                plt.pause(0.03)
        
        self.reproduciendo = False
        if plt.fignum_exists(self.fig.number):
            self.ax.set_title("Animación pausada. Presione el botón para repetir.")
            plt.draw()

    def reiniciar_animacion(self, event):
        # Clic en el botón de la interfaz
        if not self.reproduciendo:
            self.reproduciendo = True
            self.reproducir()

# Inicializar y arrancar el controlador
controlador = AnimacionCalor(frames_data, nfiles)

# Reproducción automática inicial al abrir la ventana
controlador.reproduciendo = True
controlador.reproducir()

# Mantener la ventana abierta de forma interactiva y permanente
plt.show()