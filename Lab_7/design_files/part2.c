volatile int pixel_buffer_start; // global variable

void clear_screen();
void draw_line(int x0, int y0, int x1, int y1, short int color);
void plot_pixel(int x, int y, short int line_color);
void swap(int* x, int* y);
void wait();


int main(void)
{
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    /* Read location of the pixel buffer from the pixel buffer controller */
    pixel_buffer_start = *pixel_ctrl_ptr;

    clear_screen();
    int x0 = 0, y0 = 150;
    int x1 = 319, y1 = 150;
    int yInc = 1;
    
    while (1)
    {
        draw_line(x0, y0, x1, y1, 0xF81F);
        wait();
        draw_line(x0, y0, x1, y1, 0x000);

        if (y0 == 0)
        {
            yInc *= -1;
        }
        else if (y1 == 239)
        {
            yInc *= -1;
        }

        y0 += yInc;
        y1 += yInc;
    }

    return 0;
}

// code not shown for clear_screen() and draw_line() subroutines

void plot_pixel(int x, int y, short int line_color)
{
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}

void swap(int* x, int* y)
{
    *x = *x + *y;
    *y = *x - *y;
    *x = *x - *y;
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

void wait()
{
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    volatile int * status =(int *)0xFF20302C;

    *pixel_ctrl_ptr = 1;

    while((*status & 0x01) != 0)
    {
        status = status; // keep reading status;
    }
    
    //exit when S is 1
    return;
}

void draw_line(int x0, int y0, int x1, int y1, short int color)
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