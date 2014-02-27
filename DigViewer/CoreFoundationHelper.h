//
//  CoreFoundationHelper.h
//

#ifndef CoreFoundationHelper_h
#define CoreFoundationHelper_h

template <class T, T (*RETAIN)(T), void (*RELEASE)(T)> class ECFObjectRef{
protected:
    T ref;
    
public:
    ECFObjectRef():ref(NULL){};
    explicit ECFObjectRef(T r):ref(r){};
    explicit ECFObjectRef(ECFObjectRef& r):ref(r.ref){
        RETAIN(ref);
    };
    ~ECFObjectRef(){
        if (ref){
            RELEASE(ref);
        }
    };

    bool isNULL() const {return ref == NULL;};
    
    operator T () const {return ref;};

    ECFObjectRef& transferOwnership(T src){
        if (ref){
            RELEASE(ref);
        }
        ref = src;
        return *this;
    };
    ECFObjectRef& operator = (ECFObjectRef& src){
        if (ref){
            RELEASE(ref);
        };
        ref = src.ref;
        if (ref){
            RETAIN(ref);
        }
        return *this;
    };
    ECFObjectRef& operator = (T src){
        if (ref){
            RELEASE(ref);
        }
        ref = src;
        return *this;
    };
};

template <class T> class ECFBasicObjectRef{
protected:
    T ref;
    
public:
    ECFBasicObjectRef():ref(NULL){};
    explicit ECFBasicObjectRef(T r):ref(r){};
    explicit ECFBasicObjectRef(ECFBasicObjectRef& r):ref(r.ref){
        CFRetain(ref);
    };
    ~ECFBasicObjectRef(){
        if (ref){
            CFRelease(ref);
        }
    };
    
    bool isNULL() const {return ref == NULL;};
    
    operator T () const {return ref;};
    
    ECFBasicObjectRef& transferOwnership(T src){
        if (ref){
            CFRelease(ref);
        }
        ref = src;
        return *this;
    };
    ECFBasicObjectRef& operator = (ECFBasicObjectRef& src){
        if (ref){
            CFRelease(ref);
        };
        ref = src.ref;
        if (ref){
            CFRetain(ref);
        }
        return *this;
    };
    ECFBasicObjectRef& operator = (T src){
        if (ref){
            CFRelease(ref);
        }
        ref = src;
        return *this;
    };
};

#define DEF_ECFREF_BASIC(T) typedef ECFBasicObjectRef<T##Ref> E##T##Ref
#define DEF_ECFREF_SPECIAL(T) typedef ECFObjectRef<T##Ref, T##Retain, T##Release> E##T##Ref

DEF_ECFREF_BASIC(CGImageSource);
DEF_ECFREF_BASIC(CGDataProvider);

DEF_ECFREF_SPECIAL(CGContext);
DEF_ECFREF_SPECIAL(CGColor);
DEF_ECFREF_SPECIAL(CGColorSpace);
DEF_ECFREF_SPECIAL(CGImage);
DEF_ECFREF_SPECIAL(CGPath);

#endif
