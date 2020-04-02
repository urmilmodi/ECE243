volatile int pixel_buffer_start; // global variable

void clear_screen();
void draw_line(int x0, int y0, int x1, int y1, const short int color);
void plot_pixel(const int x, const int y, const short int line_color);
void swap(int *x, int *y);


int main(void)
{
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    /* Read location of the pixel buffer from the pixel buffer controller */
    pixel_buffer_start = *pixel_ctrl_ptr;

    clear_screen();
    draw_line(0, 0, 150, 150, 0x001F);   // this line is blue
    draw_line(150, 150, 319, 0, 0x07E0); // this line is green
    draw_line(0, 239, 319, 239, 0xF800); // this line is red
    draw_line(319, 0, 0, 239, 0xF81F);   // this line is a pink color

    while (1)
    {
        
    }

    return 0;
}

// code not shown for clear_screen() and draw_line() subroutines

void plot_pixel(const int x, const int y, const short int line_color)
{
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}

void clear_screen()
{
    int x = 0, y = 0;

    for (x = 0; x < 320; ++x)
    {
        for (y = 0; y < 240; ++y)
        {
            plot_pixel(x, y, 0x0000);
        }
    }
}

void swap(int* x, int* y)
{
    *x = *x + *y;
    *y = *x - *y;
    *x = *x - *y;
}

void draw_line(int x0, int y0, int x1, int y1, const short int color)
{
    int is_steep = 0;

    int abs_x = x1 - x0;
    int abs_y = y1 - y0;

    if (abs_x < 0)
    {
        abs_x *= -1;
    }

    if (abs_y < 0)
    {
        abs_y *= -1;
    }

    is_steep = abs_y > abs_x;

    if (is_steep)
    {
        swap(&x0, &y0);
        swap(&x1, &y1);
    }

    if (x0 > x1)
    {
        swap(&x0, &x1);
        swap(&y0, &y1);
    }

    int dx = x1 - x0;
    int dy = y1 - y0;

    if (dy < 0)
    {
        dy *= -1;
    }

    int err = -(dx / 2);
    int y = y0;
    int y_step = -1;

    if (y0 < y1)
    {
        y_step = 1;
    }

    int x = x0;

    for (x = x0; x <= x1; ++x)
    {
        if (is_steep)
        {
            plot_pixel(y, x, color);
        }
        else
        {
            plot_pixel(x, y, color);
        }

        err += dy;

        if (err >= 0)
        {
            y += y_step;
            err -= dx;
        }
    }
}