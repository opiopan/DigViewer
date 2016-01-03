//
//  CoreFoundationHelper.h
//

#ifndef CoreFoundationHelper_h
#define CoreFoundationHelper_h

#import <ImageIO/ImageIO.h>

template <class T,class RT, RT (*RETAIN)(RT), void (*RELEASE)(RT)> class ECFObjectRef{
protected:
    T ref;

public:
    ECFObjectRef():ref(NULL){};
    explicit ECFObjectRef(T r, bool retain = false):ref(r){
        if (retain && ref){
            RETAIN(ref);
        }
    };
    ECFObjectRef(ECFObjectRef& r):ref(r.ref){
        if (ref){
            RETAIN(ref);
        }
    };
    ~ECFObjectRef(){
        if (ref){
            RELEASE(ref);
        }
    };

    bool isNULL() const {return ref == NULL;};
    
    T transferOwnership(){
        T rc = ref;
        ref = NULL;
        return rc;
    };
    
    operator T () const {return ref;};

    ECFObjectRef& operator = (ECFObjectRef& src){
        if (ref){
            RELEASE(ref);
        };
        ref = src.ref;
        RETAIN(ref);
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

#define DEF_ECFREF_BASIC(T) typedef ECFObjectRef<T##Ref, CFTypeRef, CFRetain, CFRelease> E##T##Ref
#define DEF_ECFREF_SPECIAL(T) typedef ECFObjectRef<T##Ref, T##Ref, T##Retain, T##Release> E##T##Ref

DEF_ECFREF_BASIC(CGImageSource);
DEF_ECFREF_BASIC(CGDataProvider);

DEF_ECFREF_SPECIAL(CGContext);
DEF_ECFREF_SPECIAL(CGColor);
DEF_ECFREF_SPECIAL(CGColorSpace);
DEF_ECFREF_SPECIAL(CGImage);
DEF_ECFREF_SPECIAL(CGPath);

#endif
