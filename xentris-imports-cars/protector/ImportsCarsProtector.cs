// Protector de pantalla Imports Cars: presenta las laminas de la carpeta "slides" con fundido y zoom lento.
// Se compila a ImportsCars.scr con csc.exe (ver compilar.ps1). Argumentos estandar de Windows: /s mostrar, /c configurar, /p vista previa.
using System;
using System.IO;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using System.Windows.Forms;
using Application = System.Windows.Application;
using Cursors = System.Windows.Input.Cursors;
using Image = System.Windows.Controls.Image;
using MessageBox = System.Windows.MessageBox;
using Panel = System.Windows.Controls.Panel;

public class Protector
{
    const double SegundosPorLamina = 9.0;
    const double SegundosFundido = 1.6;
    static string[] laminas;
    static int indice = 0;
    static bool cerrando = false;

    static string log = Path.Combine(Path.GetTempPath(), "ImportsCars-protector.log");
    static void Log(string m) { try { File.AppendAllText(log, DateTime.Now.ToString("HH:mm:ss ") + m + Environment.NewLine); } catch { } }

    [STAThread]
    public static void Main(string[] args)
    {
        try { Correr(args); } catch (Exception ex) { Log("ERROR " + ex); }
    }

    static void Correr(string[] args)
    {
        Log("inicio " + string.Join(" ", args));
        string modo = args.Length > 0 ? args[0].ToLowerInvariant().Substring(0, Math.Min(2, args[0].Length)) : "/s";
        if (modo == "/p") return; // la vista previa pequena no se dibuja
        if (modo == "/c") { MessageBox.Show("Protector Imports Cars\n\nLas laminas estan en la carpeta 'slides' junto a este archivo.\nCambia las imagenes PNG ahi para actualizar el protector.", "Imports Cars", MessageBoxButton.OK, MessageBoxImage.Information); return; }

        string dir = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);
        laminas = Directory.GetFiles(Path.Combine(dir, "slides"), "*.png").OrderBy(f => f).ToArray();
        if (laminas.Length == 0) return;

        var app = new Application();
        app.ShutdownMode = ShutdownMode.OnLastWindowClose;
        Window principal = null;
        foreach (var pantalla in Screen.AllScreens)
        {
            var w = CrearVentana(pantalla, pantalla.Primary);
            if (pantalla.Primary) principal = w;
            w.Show();
        }
        Log("laminas: " + laminas.Length + ", pantallas: " + Screen.AllScreens.Length);
        app.Run(principal);
        Log("fin");
    }

    static Window CrearVentana(Screen pantalla, bool conLaminas)
    {
        var w = new Window();
        w.WindowStyle = WindowStyle.None; w.ResizeMode = ResizeMode.NoResize; w.ShowInTaskbar = false;
        w.Topmost = true; w.Background = new SolidColorBrush(Color.FromRgb(0x15, 0x17, 0x19)); w.Cursor = Cursors.None;
        w.WindowStartupLocation = WindowStartupLocation.Manual;
        w.Left = pantalla.Bounds.Left; w.Top = pantalla.Bounds.Top; w.Width = pantalla.Bounds.Width; w.Height = pantalla.Bounds.Height;
        w.Loaded += (s, e) => { w.WindowState = WindowState.Maximized; };

        System.Windows.Point? origen = null;
        w.KeyDown += (s, e) => Cerrar("tecla " + e.Key);
        w.MouseDown += (s, e) => Cerrar("clic");
        w.MouseMove += (s, e) =>
        {
            var p = e.GetPosition(w);
            if (origen == null) { origen = p; return; }
            if (Math.Abs(p.X - origen.Value.X) + Math.Abs(p.Y - origen.Value.Y) > 14) Cerrar("mouse");
        };

        if (conLaminas)
        {
            var grid = new Grid();
            var a = NuevaImagen(); var b = NuevaImagen();
            grid.Children.Add(a); grid.Children.Add(b);
            w.Content = grid;
            Image visible = a, oculta = b;
            Mostrar(visible, laminas[0], true);
            var timer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(SegundosPorLamina) };
            timer.Tick += (s, e) =>
            {
                indice = (indice + 1) % laminas.Length;
                Mostrar(oculta, laminas[indice], false);
                var tmp = visible; visible = oculta; oculta = tmp;
            };
            timer.Start();
        }
        return w;
    }

    static Image NuevaImagen()
    {
        var img = new Image { Stretch = Stretch.UniformToFill, Opacity = 0, RenderTransformOrigin = new System.Windows.Point(0.5, 0.5) };
        img.RenderTransform = new ScaleTransform(1, 1);
        RenderOptions.SetBitmapScalingMode(img, BitmapScalingMode.HighQuality);
        return img;
    }

    static void Mostrar(Image img, string ruta, bool inmediato)
    {
        var bmp = new BitmapImage(); bmp.BeginInit(); bmp.CacheOption = BitmapCacheOption.OnLoad; bmp.UriSource = new Uri(ruta); bmp.EndInit(); bmp.Freeze();
        img.Source = bmp;
        Panel.SetZIndex(img, 1);
        foreach (UIElement otro in ((Grid)img.Parent).Children) if (otro != img) Panel.SetZIndex(otro, 0);
        var fade = new DoubleAnimation(0, 1, TimeSpan.FromSeconds(inmediato ? 0.01 : SegundosFundido)) { EasingFunction = new SineEase() };
        img.BeginAnimation(UIElement.OpacityProperty, fade);
        var st = (ScaleTransform)img.RenderTransform;
        var zoom = new DoubleAnimation(1.0, 1.06, TimeSpan.FromSeconds(SegundosPorLamina + SegundosFundido + 1));
        st.BeginAnimation(ScaleTransform.ScaleXProperty, zoom);
        st.BeginAnimation(ScaleTransform.ScaleYProperty, zoom);
    }

    static void Cerrar(string motivo)
    {
        if (cerrando) return; cerrando = true; Log("cierre por " + motivo);
        Application.Current.Shutdown();
    }
}
