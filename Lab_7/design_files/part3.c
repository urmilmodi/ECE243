#include <stdlib.h>
volatile int pixel_buffer_start; // global variable

void clear_screen();
void draw_line(int x0, int y0, int x1, int y1, short int color);
void plot_pixel(int x, int y, short int line_color);
void swap(int* x, int* y);
void wait();

int main(void)
{
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    int N = 8;
    int x[N], y[N], xInc[N], yInc[N], colour[N];
    short int colourlist[] = {0xF800, 0x07E0, 0x001F, 0xFFE0, 0xF81F, 0x07FF};

    int i = 0;
    for (i = 0; i < N; ++i)
    {
        x[i] = rand () % 319;
        y[i] = rand () % 239;
        colour[i] = colourlist[rand() % 6];

        xInc[i] = rand() % 2 * 2 - 1;
        yInc[i] = rand() % 2 * 2 - 1;
    }

    // declare other variables(not shown)
    // initialize location and direction of rectangles(not shown)

    /* set front pixel buffer to start of FPGA On-chip memory */
    *(pixel_ctrl_ptr + 1) = 0xC8000000; // first store the address in the 
                                        // back buffer
    /* now, swap the front/back buffers, to set the front buffer location */
    wait();
    /* initialize a pointer to the pixel buffer, used by drawing functions */
    pixel_buffer_start = *pixel_ctrl_ptr;
    clear_screen(); // pixel_buffer_start points to the pixel buffer
    /* set back pixel buffer to start of SDRAM memory */
    *(pixel_ctrl_ptr + 1) = 0xC0000000;
    pixel_buffer_start = *(pixel_ctrl_ptr + 1); // we draw on the back buffer

    while (1)
    {
        /* Erase any boxes and lines that were drawn in the last iteration */
        clear_screen();

        // code for drawing the boxes
        int i = 0;
        for (i = 0; i < N; ++i)
        {
            //draw circle
            plot_pixel(x[i], y[i], colour[i]);
            plot_pixel(x[i] +1 , y[i], colour[i]);
            plot_pixel(x[i], y[i] + 1, colour[i]);
            plot_pixel(x[i] + 1, y[i] + 1, colour[i]);

            //draw line
            if (i<=7) draw_line(x[i], y[i], x[i+1], y[i+1], 0xFFFF);

            // code for updating the locations of boxes
            if (x[i] == 0)
            {
                xInc[i] *= -1;
            }
            else if (x[i] == 318)
            {
                xInc[i] *= -1;
            }

            if (y[i] == 0)
            {
                yInc[i] *= -1;
            }
            else if (y[i] == 238)
            {
                yInc[i] *= -1;
            }

            x[i] += xInc[i];
            y[i] += yInc[i];
        }

        // code for drawing the boxes and lines (not shown)
        // code for updating the locations of boxes (not shown)

        wait(); // swap front and back buffers on VGA vertical sync
        pixel_buffer_start = *(pixel_ctrl_ptr + 1); // new back buffer
    }

    return 0;
}

// code for subroutines (not shown)
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
