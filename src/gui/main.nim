import nigui
import ../screep/scraper

type
  TextEditor = ref object of ContainerImpl


proc text_editor_control: TextEditor =
  result = new TextEditor
  result.widthMode = WidthMode_Fill
  result.heightMode = HeightMode_Fill
  var b = newButton()
  b.text= "hasdiasidajsdi"
  result.add b
  result.onDraw = proc (event: DrawEvent) =
    let c = event.control.canvas
    c.areaColor=rgb(0,0,0)
    c.fill

var cont: LayoutContainer

proc start_gui* =
  app.init()
  # Initialization is mandatory.

  var window = newWindow(version)
  # Create a window with a given title:
  # By default, a window is empty and not visible.
  # It is played at the center of the screen.
  # A window can contain only one control.
  # A container can contain multiple controls.

  window.width = 600.scaleToDpi
  window.height = 400.scaleToDpi
  # Set the size of the window

  window.iconPath = "icon.png"
  # The window icon can be specified this way.
  # The default value is the name of the executable file without extension + ".png"

  var container = newLayoutContainer(Layout_Vertical)
  # Create a container for controls.
  # By default, a container is empty.
  # It's size will adapt to it's child controls.
  # A LayoutContainer will automatically align the child controls.
  # The layout is set to clhorizontal.

  window.add(container)
  # Add the container to the window.

  # var button = newButton("Button 1")
  # # Create a button with a given title.

  # container.add(button)
  # # Add the button to the container.

  # var textArea = newTextArea()
  # # Create a multiline text box.
  # # By default, a text area is empty and editable.

  # container.add(textArea)
  # # Add the text area to the container.

  # button.onClick = proc(event: ClickEvent) =
  # # Set an event handler for the "onClick" event (here as anonymous proc).

  #   textArea.addLine("Button 1 clicked, message box opened.")
  #   window.alert("This is a simple message box.")
  #   textArea.addLine("Message box closed.")

  # var te = text_editor_control()
  # window.add te

  window.show()
  # Make the window visible on the screen.
  # Controls (containers, buttons, ..) are visible by default.

  app.run()
  # At last, run the main loop.
  # This processes incoming events until the application quits.
  # To quit the application, dispose all windows or call "app.quit()".


when isMainModule:
  start_gui()