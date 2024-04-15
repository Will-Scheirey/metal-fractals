//
//  ComplexNumbers.metal
//  shaders
//
//  Created by William Scheirey on 10/10/23.
//

#include <metal_stdlib>
using namespace metal;

template<typename T>
struct ComplexNumber
{
    T a, b;

    ComplexNumber(T x, T y) : a(x), b(y) { }
    
    T sqmag() const {
        return a*a + b*b;
    }
    
    T r() const {
        return sqrt(sqmag());
    }
    
    T theta() const {
        return atan2(a, b);
    }
    
    ComplexNumber<T> operator*(const thread ComplexNumber<T>& other) const {
        return ComplexNumber(a*other.a - b*other.b,
                       a*other.b + b*other.a);
    }
    
    ComplexNumber<T> operator+(const thread ComplexNumber<T>& other) const {
        return ComplexNumber(a + other.a, b + other.b);
    }
    
    ComplexNumber<T> operator-(const thread ComplexNumber<T>& other) const {
        return ComplexNumber(a - other.a, b - other.b);
    }
    
    ComplexNumber<T> operator*(const thread T& c) const {
        return ComplexNumber(a * c, b * c);
    }
};

template<typename T>
ComplexNumber<T> pow(ComplexNumber<T> num, float n)
{
    
    if(n == 2 || n == 3 || n == 4)
    {
        if(n == 2)
            return num * num;
        if(n == 3)
            return num * num * num;
        return num * num * num * num;
    }
     
    float r = pow(num.r(), n);
    float t = num.theta() * n;
    
    return ComplexNumber<T>(r * cos(t), r * sin(t));
}

template<typename T>
ComplexNumber<T> pow(ComplexNumber<T> num, ComplexNumber<T> power)
{
    float ri = num.r();
    float ti = num.theta();
    
    float r = pow(M_E_F, power.a * log(ri) - power.b * ti - 2*M_PI_F*power.b);
    float theta = power.b * log(ri) + power.a*ti + 2*M_PI_F*power.a;
    
    return ComplexNumber<float>(r * sin(theta - M_PI_2_F), r * cos(theta - M_PI_2_F));
}


// Trig

template<typename T>
ComplexNumber<T> sin(ComplexNumber<T> num)
{
    return ComplexNumber<T>(sin(num.a) * cosh(num.b), -cos(num.a)*sinh(num.b));
}

template<typename T>
ComplexNumber<T> cos(ComplexNumber<T> num)
{
    return ComplexNumber<T>(cos(num.a) * cosh(num.b), -sin(num.a)*sinh(num.b));
}

template<typename T>
ComplexNumber<T> sinh(ComplexNumber<T> num)
{
    return ComplexNumber<T>(sinh(num.a) * cos(num.b), cosh(num.a)*sin(num.b));
}

template<typename T>
ComplexNumber<T> cosh(ComplexNumber<T> num)
{
    return ComplexNumber<T>(cosh(num.a) * cos(num.b), sinh(num.a)*sin(num.b));
}




