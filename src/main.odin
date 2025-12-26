package main

import "core:fmt"
import "vendor:raylib"

SCREEN_WIDTH :: 900
SCREEN_HEIGHT :: 600
SQUARE_SIZE :: 30
GRID_ROWS :: SCREEN_HEIGHT / SQUARE_SIZE
GRID_COLUMNS :: SCREEN_WIDTH / SQUARE_SIZE

State :: enum {
    Setup = 1,
    Running = 2,
    Paused = 3,
}

Cell :: distinct bool

App :: struct {
    state: State,
    cells: [GRID_ROWS][GRID_COLUMNS]Cell,
    grid_texture: raylib.RenderTexture2D,
}

init_grid :: proc(grid_texture: raylib.RenderTexture2D) {
    raylib.BeginTextureMode(grid_texture)

    for i in 1..=GRID_ROWS {
        raylib.DrawLineV(
            {0, f32(i * SQUARE_SIZE)},
            {SCREEN_WIDTH, f32(i * SQUARE_SIZE)},
            raylib.GRAY,
        )
    }

    for i in 1..<GRID_COLUMNS {
        raylib.DrawLineV(
            {f32(i * SQUARE_SIZE), 0},
            {f32(i * SQUARE_SIZE), SCREEN_HEIGHT},
            raylib.GRAY,
        )
    }

    raylib.EndTextureMode()
}

update_cells_grid :: proc(cells: ^[GRID_ROWS][GRID_COLUMNS]Cell) {
    old_grid := cells^

    for row_idx in 0..<GRID_ROWS {
        for column_idx in 0..<GRID_COLUMNS {
            live_cells_around := 0

            if row_idx > 0 && column_idx > 0 {
                live_cells_around += int(old_grid[row_idx - 1][column_idx - 1])
            }

            if row_idx > 0 {
                live_cells_around += int(old_grid[row_idx - 1][column_idx])
            }

            if row_idx > 0 && column_idx < GRID_COLUMNS - 1 {
                live_cells_around += int(old_grid[row_idx - 1][column_idx + 1])
            }

            if column_idx > 0 {
                live_cells_around += int(old_grid[row_idx][column_idx - 1])
            }

            if column_idx < GRID_COLUMNS - 1 {
                live_cells_around += int(old_grid[row_idx][column_idx + 1])
            }

            if row_idx < GRID_ROWS - 1 && column_idx > 0 {
                live_cells_around += int(old_grid[row_idx + 1][column_idx - 1])
            }

            if row_idx < GRID_ROWS - 1 {
                live_cells_around += int(old_grid[row_idx + 1][column_idx])
            }

            if row_idx < GRID_ROWS - 1 && column_idx < GRID_COLUMNS - 1 {
                live_cells_around += int(old_grid[row_idx + 1][column_idx + 1])
            }

            if old_grid[row_idx][column_idx] {
                if live_cells_around < 2 {
                    cells[row_idx][column_idx] = false
                } else if live_cells_around == 2 || live_cells_around == 3 {
                    cells[row_idx][column_idx] = true
                } else {
                    cells[row_idx][column_idx] = false
                }
            } else {
                if live_cells_around == 3 {
                    cells[row_idx][column_idx] = true
                }
            }
        }
    }
}

draw_grid :: proc(app: ^App) {
    for row_idx in 0..<GRID_ROWS {
        for column_idx in 0..<GRID_COLUMNS {
            raylib.DrawRectangle(
                i32(column_idx * SQUARE_SIZE),
                i32(row_idx * SQUARE_SIZE),
                SQUARE_SIZE,
                SQUARE_SIZE,
                app.cells[row_idx][column_idx] ? raylib.WHITE : raylib.BLACK,
            )
        }
    }

    raylib.DrawTexture(app.grid_texture.texture, 0, 0, raylib.WHITE)
}

keyboard_input_handler :: proc(app: ^App) {
    switch app.state {
    case .Setup:
        #partial switch raylib.GetKeyPressed() {
        case raylib.KeyboardKey.ENTER:
            raylib.SetWindowTitle("Game of life - Running")
            raylib.SetTargetFPS(15)

            app.state = State.Running
        case raylib.KeyboardKey.R:
            app.state = State.Setup
            app.cells = {}
        }
    case .Running:
        #partial switch raylib.GetKeyPressed() {
        case raylib.KeyboardKey.P:
            raylib.SetWindowTitle("Game of life - Paused")

            app.state = State.Paused
        case raylib.KeyboardKey.R:
            raylib.SetWindowTitle("Game of life - Setup")
            raylib.SetTargetFPS(60)

            app.state = State.Setup
            app.cells = {}
        }
    case .Paused:
        #partial switch raylib.GetKeyPressed() {
        case raylib.KeyboardKey.P:
            raylib.SetWindowTitle("Game of life - Running")

            app.state = State.Running
        case raylib.KeyboardKey.R:
            raylib.SetWindowTitle("Game of life - Setup")
            raylib.SetTargetFPS(60)

            app.state = State.Setup
            app.cells = {}
        }
    }

}

mouse_input_handler :: proc(app: ^App) {
    mouse_x, mouse_y := raylib.GetMouseX(), raylib.GetMouseY()

    if mouse_x < 0 || mouse_x >= SCREEN_WIDTH {
        return
    }

    if mouse_y < 0 || mouse_y >= SCREEN_HEIGHT {
        return
    }

    cell_row := mouse_y / SQUARE_SIZE
    cell_column := mouse_x / SQUARE_SIZE

    if raylib.IsMouseButtonDown(raylib.MouseButton.LEFT) {
        app.cells[cell_row][cell_column] = true
    } else if raylib.IsMouseButtonDown(raylib.MouseButton.RIGHT) {
        app.cells[cell_row][cell_column] = false
    }
}

setup_screen :: proc(app: ^App) {
    keyboard_input_handler(app)
    mouse_input_handler(app)

    raylib.BeginDrawing()

    raylib.ClearBackground(raylib.BLACK)

    draw_grid(app)

    raylib.EndDrawing()
}

running_screen :: proc(app: ^App) {
    if app.state == State.Paused {
        mouse_input_handler(app)
    }

    keyboard_input_handler(app)

    raylib.BeginDrawing()

    raylib.ClearBackground(raylib.BLACK)

    raylib.DrawTexture(app.grid_texture.texture, 0, 0, raylib.WHITE)

    draw_grid(app)

    raylib.EndDrawing()

    if app.state == State.Running {
        update_cells_grid(&app.cells)
    }
}

main :: proc() {
    raylib.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Game of life - Setup")

    raylib.SetTargetFPS(60)

    app := App {
        state = State.Setup,
        cells = {},
        grid_texture = raylib.LoadRenderTexture(
            SCREEN_WIDTH,
            SCREEN_HEIGHT,
        ),
    }

    init_grid(app.grid_texture)

    for !raylib.WindowShouldClose() {
        switch app.state {
        case .Setup: setup_screen(&app)
        case .Running, .Paused: running_screen(&app)
        }
    }

    raylib.UnloadRenderTexture(app.grid_texture)

    raylib.CloseWindow()
}
