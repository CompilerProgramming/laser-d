struct CPoint
{
    int x;
    int y;
};

enum CColour
{
    red = 1,
    green = 2,
    blue = 4
};

int importc_global = 7;
long double importc_extended = 1.0L;

struct CPoint make_point(int x, int y)
{
    struct CPoint result = { x, y };
    return result;
}

int sum_point(struct CPoint point)
{
    return point.x + point.y;
}
