import
  std/os,
  std/random,
  std/strutils,
  std/sugar,
  sdl2

discard sdl2.init(INIT_EVERYTHING)

var 
  window: WindowPtr
  render: RendererPtr

window = createWindow("Game of life", 100, 100, 640, 480, SDL_WINDOW_SHOWN)
render = createRenderer(window, -1, Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture)

type
  Colour = tuple
    r, g, b, a: uint8

  Grid = array[620, array[460, bool]]

proc colourFromHex(hexstring: string): Colour =
  proc hextouint(hex: string): uint8 =
    uint8 hex.parseHexInt()

  var hex = hexstring
  if hex.startsWith('#'):
    hex = hex[1..hex.high]
  doAssert(hex.len == 8, "Hex string was not 8")
  result.r = hextouint hex[0..1]
  result.g = hextouint hex[2..3]
  result.b = hextouint hex[4..5]
  result.a = hextouint hex[6..7]

proc setDrawColor(render: RendererPtr, colour: Colour) =
  render.setDrawColor(colour.r, colour.g, colour.b, colour.a)

proc drawRectangle(render: RendererPtr, x, y, w, h :cint , colour: Colour) =
  var rectangle = rect(x, y, w, h)

  render.setDrawColor colour
  render.fillRect rectangle

proc drawPixel(render: RendererPtr, x, y: cint, colour: Colour) =
  render.drawRectangle(x, y, 10, 10, colour)

proc drawCoordinate(renderer: RendererPtr, row, col: cint, colour: Colour) =
  render.drawPixel(col * 10 + 10, row * 10 + 10, colour)

proc drawGrid(renderer: RendererPtr, grid: Grid, colour: Colour) =
  for row in 0..<grid.len:
    for col in 0..<grid[0].len:
      if grid[row][col]:
        render.drawCoordinate(row.cint, col.cint, colour)

proc `+`(self, other: (int, int)): (int, int) =
  (self[0] + other[0], self[1] + other[1])

proc on(grid: var Grid, row, col: int) =
  grid[row][col] = true

proc off(grid: var Grid, row, col: int) =
  grid[row][col] = false

proc isAlive(grid: Grid, point: (int, int)): bool =
  let (row, col) = point
  if row < 0 or row > grid.len - 1:
    return false
  if col < 0 or col > grid[0].len - 1:
    return false
  return grid[row][col]

proc countLiveNeighbours(grid: Grid, row, col: int): int =
  let cur = (row, col)
#  if row < 4 and col < 4:
#    echo "checking coords"
#    dump cur + (-1, -1)
#    dump cur + (-1, -0)
#    dump cur + (0, -1)
#    dump cur + (0, 1)
#    dump cur + (1, -1)
#    dump cur + (1, 0)
#    dump cur + (1, -1)
    
  if grid.isAlive cur + (-1, -1):
    result += 1
  if grid.isAlive cur + (-1, 0):
    result += 1
  if grid.isAlive cur + (-1, 1):
    result += 1
  if grid.isAlive cur + (0, -1):
    result += 1
  if grid.isAlive cur + (0, 1):
    result += 1
  if grid.isAlive cur + (1, -1):
    result += 1
  if grid.isAlive cur + (1, 0):
    result += 1
  if grid.isAlive cur + (1, 1):
    result += 1

proc getNextGeneration(grid: Grid): Grid =
  for row in 0..<grid.len:
    for col in 0..<grid[0].len:
      let
        selfAlive = grid[row][col]
        aliveNeighbours = grid.countLiveNeighbours(row, col)
      #if row < 4 and col < 4:
      #  dump row
      #  dump col
      #  dump selfAlive
      #  dump aliveNeighbours

      if selfAlive and (aliveNeighbours == 2 or aliveNeighbours == 3):
        result.on(row, col)
      elif not selfAlive and aliveNeighbours == 3:
        result.on(row, col)
      else:
        result.off(row, col)

proc isEmpty(grid: Grid): bool =
  for row in 0..<grid.len:
    for col in 0..<grid[0].len:
      if grid[row][col]:
        return false
  return true

type 
  GameState = enum
    Setting,
    Playing

var
  event = sdl2.defaultEvent
  runGame = true
  colour = colourFromHex "#FFFFFF00"
  field: Grid
  generation = 0
  gamestate = GameState.Setting

field.on(1, 1)
field.on(2, 2)
field.on(2, 3)
field.on(3, 1)
field.on(3, 2)

field.on(1, 5)
field.on(2, 6)
field.on(2, 7)
field.on(3, 5)
field.on(3, 6)


while runGame:
  while pollEvent(event):
    case event.kind:
      of QuitEvent:
        runGame = false
        break
      of KeyDown:
        case event.key.keysym.scancode:
          of SDL_SCANCODE_Q:
            runGame=false
            break
          of SDL_SCANCODE_SPACE:
            if gamestate == Setting:
              gamestate = Playing
            else:
              gamestate = Setting
          else:
            discard
      of MouseButtonDown:
        if gamestate == Setting:
          let mouseEvent = event.evMouseButton()
          let row = (mouseEvent.y - 10) div 10
          let col = (mouseEvent.x - 10) div 10
          let button = mouseEvent.button
          if button == 1:
            field.on(row, col)
          elif button == 3:
            field.off(row,col)
      else: discard

  render.setDrawColor 0, 0, 0, 255
  
  render.clear()
  
  case gamestate:
    of Playing:
      field = field.getNextGeneration()

      dump generation
      generation += 1

    of Setting:
      discard
      
  render.drawGrid(field, colour)
  render.present()
  sleep 100
  

destroy render
destroy window
