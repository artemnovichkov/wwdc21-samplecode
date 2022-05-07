/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of common utility functions.
*/

#import "AAPLUtility.hpp"
#import "AAPLMathUtilities.h"
#import "AAPLShaderTypes.h"

#import <Foundation/Foundation.h>
#import <ImageIO/ImageIO.h>
#import <Metal/Metal.h>

#import <simd/simd.h>
#import <vector>

namespace Utility
{
#pragma mark -
#pragma mark Internal Methods

#pragma mark Texture Load

static CGImageRef CreateCGImageFromFile (NSString* path)
{
    // Get the URL for the pathname passed to the function.
    NSURL *url = [NSURL fileURLWithPath:path];
    CGImageRef        myImage = NULL;
    CGImageSourceRef  myImageSource;
    CFDictionaryRef   myOptions = NULL;
    CFStringRef       myKeys[2];
    CFTypeRef         myValues[2];

    // Set up options if you want them. The options here are for
    // caching the image in a decoded form and for using floating-point
    // values if the image format supports them.
    myKeys[0] = kCGImageSourceShouldCache;
    myValues[0] = (CFTypeRef)kCFBooleanFalse;

    myKeys[1] = kCGImageSourceShouldAllowFloat;
    myValues[1] = (CFTypeRef)kCFBooleanTrue;

    // Create the dictionary
    myOptions = CFDictionaryCreate(NULL,
                                   (const void **) myKeys,
                                   (const void **) myValues, 2,
                                   &kCFTypeDictionaryKeyCallBacks,
                                   & kCFTypeDictionaryValueCallBacks);

    // Create an image source from the URL.
    myImageSource = CGImageSourceCreateWithURL((CFURLRef)url, myOptions);
    CFRelease(myOptions);

    // Make sure the image source exists before continuing
    if (myImageSource == NULL)
    {
        fprintf(stderr, "Image source is NULL.");
        return  NULL;
    }

    // Create an image from the first item in the image source.
    myImage = CGImageSourceCreateImageAtIndex(myImageSource, 0, NULL);
    CFRelease(myImageSource);

    // Make sure the image exists before continuing
    if (myImage == NULL)
    {
         fprintf(stderr, "Image not created from image source.");
         return NULL;
    }

    return myImage;
}

#pragma mark Geometry

#pragma mark Sphere

/// A helpful primitive definition for generating a sphere
struct SphereTriangle
{
    vector_float3 v0;
    vector_float3 v1;
    vector_float3 v2;

    typedef std::vector<SphereTriangle> Vector;
};

/*
    This method starts with an octahedron and then subdivides each face into new
    triangles. Each newly generated vertex is simply pushed out along the
    surface normal at that point.

    NOTE: Be careful with the number of iterations, as the triangles generated
        increase rapidly: 2^(2*i + 3) where i is the number of iterations.
*/
static SphereTriangle::Vector s_GenSphere(uint32_t iterations)
{
    // Prevent overflow, but hopefully you aren't actually trying to generate 2^31 triangles...
    iterations = iterations > 14 ? 14 : iterations;

    // Assemble the initial case - an octahedron
    static const vector_float3 SPHERE_POSITIONS[] =
    {
        vector_float3{  0,  0,  1},
        vector_float3{  0,  0, -1},
        vector_float3{  1,  0,  0},
        vector_float3{  0,  1,  0},
        vector_float3{ -1,  0,  0},
        vector_float3{  0, -1,  0}
    };

    static const SphereTriangle BASE[] =
    {
        {SPHERE_POSITIONS[0], SPHERE_POSITIONS[2], SPHERE_POSITIONS[3]},
        {SPHERE_POSITIONS[0], SPHERE_POSITIONS[3], SPHERE_POSITIONS[4]},
        {SPHERE_POSITIONS[0], SPHERE_POSITIONS[4], SPHERE_POSITIONS[5]},
        {SPHERE_POSITIONS[0], SPHERE_POSITIONS[5], SPHERE_POSITIONS[2]},

        {SPHERE_POSITIONS[1], SPHERE_POSITIONS[2], SPHERE_POSITIONS[5]},
        {SPHERE_POSITIONS[1], SPHERE_POSITIONS[5], SPHERE_POSITIONS[4]},
        {SPHERE_POSITIONS[1], SPHERE_POSITIONS[4], SPHERE_POSITIONS[3]},
        {SPHERE_POSITIONS[1], SPHERE_POSITIONS[3], SPHERE_POSITIONS[2]}
    };

    // Alternate between two buffers for reading and writing new triangles
    SphereTriangle::Vector lists[] = { SphereTriangle::Vector(), SphereTriangle::Vector() };
    uint32_t read = 0, write = 1;
    static const uint32_t TRI_COUNT = 1 << (2 * iterations + 3);

    lists[read].reserve(TRI_COUNT);
    lists[write].reserve(TRI_COUNT);

    // Init the first read list
    for (const SphereTriangle& tri : BASE)
    {
        lists[read].push_back(tri);
    }

    vector_float3 scratch[6];

    vector_float3 (^genMidPoint)(const vector_float3&, const vector_float3&) = ^vector_float3(const vector_float3& a, const vector_float3& b)
    {
        return vector_precise_normalize(vector_float3{(a.x + b.x) * .5f, (a.y + b.y) * .5f, (a.z + b.z) * .5f});
    };

    for (uint32_t currIteration = 0; currIteration < iterations; ++currIteration)
    {
        const SphereTriangle::Vector& readBuffer = lists[read];
        SphereTriangle::Vector& writeBuffer = lists[write];

        writeBuffer.clear();

        for (const SphereTriangle& st : readBuffer)
        {
            scratch[0] = st.v0;
            scratch[1] = genMidPoint(st.v0, st.v1);
            scratch[2] = st.v1;
            scratch[3] = genMidPoint(st.v1, st.v2);
            scratch[4] = st.v2;
            scratch[5] = genMidPoint(st.v2, st.v0);

            writeBuffer.push_back({scratch[0], scratch[1], scratch[5]});
            writeBuffer.push_back({scratch[1], scratch[2], scratch[3]});
            writeBuffer.push_back({scratch[3], scratch[4], scratch[5]});
            writeBuffer.push_back({scratch[1], scratch[3], scratch[5]});
        }

        read = write;
        write = ++write % 2;
    }

    return lists[read];
}

}; //namespace Utility

#pragma mark -
#pragma mark Exposed Methods

#pragma mark Math Helpers

// --
float lerpf(float v0, float v1, float t)
{
    return ((1.f - t) * v0) + (t * v1);
}

#pragma mark UI Option Enum Strings

// --
NSString * string_for_tonemap_operator_type(uint32_t typeIndex)
{
    switch (typeIndex)
    {
        case kTonemapOperatorTypeReinhard: return @"Reinhard";
        case kTonemapOperatorTypeReinhardEx: return @"Reinhard Extended";
        default: return @"Unknown";
    }
}

// --
NSString * string_for_exposure_control_type(uint32_t typeIndex)
{
    switch (typeIndex)
    {
        case kExposureControlTypeManual: return @"Manual Exposure";
        case kExposureControlTypeKey: return @"Key Exposure";
        default: return @"Unknown";
    }
}

#pragma mark Geometry

/// Creates an array of AAPLVertex representing position and normals for a unit sphere
/// Caller is responsible for freeing data
AAPLVertex * generate_sphere_data(uint32_t * vertexCount)
{
    const uint32_t NUM_SPHERE_ITERATIONS = 4;
    Utility::SphereTriangle::Vector sphere = Utility::s_GenSphere(NUM_SPHERE_ITERATIONS);
    const uint32_t triCount = static_cast<uint32_t>(sphere.size());
    const uint32_t vtxCount = triCount * 3;

    AAPLVertex * sVerts = new AAPLVertex[vtxCount];

    for (size_t iTri = 0; iTri < triCount; ++iTri)
    {
        size_t iVert = iTri * 3;
        sVerts[iVert].position = sphere[iTri].v0;
        sVerts[iVert].normal = sphere[iTri].v0;

        sVerts[iVert + 1].position = sphere[iTri].v1;
        sVerts[iVert + 1].normal = sphere[iTri].v1;

        sVerts[iVert + 2].position = sphere[iTri].v2;
        sVerts[iVert + 2].normal = sphere[iTri].v2;
    }

    *vertexCount = vtxCount;
    return sVerts;
}

/// Frees the sphere data
void delete_sphere_data(AAPLVertex* data)
{
    if (data)
    {
        delete [] data;
        data = nullptr;
    }
}

#pragma mark Texture Load

// --
id<MTLTexture> texture_from_radiance_file(NSString * fileName, id<MTLDevice> device, NSError ** error)
{
    // --------------
    // Validate input

    if (![fileName containsString:@"."])
    {
        if (error != NULL)
        {
            *error = [[NSError alloc] initWithDomain:@"File load failure."
                                                code:0xdeadbeef
                                            userInfo:@{NSLocalizedDescriptionKey : @"No file extension provided."}];
        }
        return nil;
    }

    NSArray * subStrings = [fileName componentsSeparatedByString:@"."];

    if ([subStrings[1] compare:@"hdr"] != NSOrderedSame)
    {
        if (error != NULL)
        {
            *error = [[NSError alloc] initWithDomain:@"File load failure."
                                                code:0xdeadbeef
                                            userInfo:@{NSLocalizedDescriptionKey : @"Only (.hdr) files are supported."}];
        }
        return nil;
    }

    //------------------------
    // Load and Validate Image

    NSString* filePath = [[NSBundle mainBundle] pathForResource:subStrings[0] ofType:subStrings[1]];
    CGImageRef loadedImage = Utility::CreateCGImageFromFile(filePath);

    if (loadedImage == NULL)
    {
        if (error != NULL)
        {
            *error = [[NSError alloc] initWithDomain:@"File load failure."
                                                code:0xdeadbeef
                                            userInfo:@{NSLocalizedDescriptionKey : @"Unable to create CGImage."}];
        }

        return nil;
    }

    size_t bpp = CGImageGetBitsPerPixel(loadedImage);

    const size_t kSrcChannelCount = 3;
    const size_t kBitsPerByte = 8;
    const size_t kExpectedBitsPerPixel = sizeof(uint16_t) * kSrcChannelCount * kBitsPerByte;

    if (bpp != kExpectedBitsPerPixel)
    {
        if (error != NULL)
        {
            *error = [[NSError alloc] initWithDomain:@"File load failure."
                                                code:0xdeadbeef
                                            userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Expected %zu bits per pixel, but file returns %zu", kExpectedBitsPerPixel, bpp]}];
        }
        CFRelease(loadedImage);
        return nil;
    }

    //----------------------------
    // Copy image into temp buffer

    size_t width = CGImageGetWidth(loadedImage);
    size_t height = CGImageGetHeight(loadedImage);

    // Make CG image data accessible
    CFDataRef cgImageData = CGDataProviderCopyData(CGImageGetDataProvider(loadedImage));

    // Get a pointer to the data
    const uint16_t * srcData = (const uint16_t * )CFDataGetBytePtr(cgImageData);

    // Metal exposes an RGBA16Float format, but source data is RGB F16, so extra channel of padding added
    const size_t kPixelCount = width * height;
    const size_t kDstChannelCount = 4;
    const size_t kDstSize = kPixelCount * sizeof(uint16_t) * kDstChannelCount;

    uint16_t * dstData = (uint16_t *)malloc(kDstSize);

    for (size_t texIdx = 0; texIdx < kPixelCount; ++texIdx)
    {
        const uint16_t * currSrc = srcData + (texIdx * kSrcChannelCount);
        uint16_t * currDst = dstData + (texIdx * kDstChannelCount);

        currDst[0] = currSrc[0];
        currDst[1] = currSrc[1];
        currDst[2] = currSrc[2];
        currDst[3] = float16_from_float32(1.f);
    }

    //------------------
    // Create MTLTexture

    MTLTextureDescriptor * texDesc = [MTLTextureDescriptor new];

    texDesc.pixelFormat = MTLPixelFormatRGBA16Float;
    texDesc.width = width;
    texDesc.height = height;

    id<MTLTexture> texture = [device newTextureWithDescriptor:texDesc];

    const NSUInteger kBytesPerRow = sizeof(uint16_t) * kDstChannelCount * width;

    MTLRegion region = { {0,0,0}, {width, height, 1} };

    [texture replaceRegion:region mipmapLevel:0 withBytes:dstData bytesPerRow:kBytesPerRow];

    // Remember to clean things up
    free(dstData);
    CFRelease(cgImageData);
    CFRelease(loadedImage);

    return texture;
}
