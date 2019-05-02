#import "EAGLView.h"

#import "MWMMapEngine.h"
#import "MWMMapEngine+Private.h"
#import "MWMMapSymbols.h"

#import "drape/drape_global.hpp"
#import "drape/visual_scale.hpp"
#import "base/assert.hpp"
#import "base/logging.hpp"
#import "map/framework.hpp"

#ifdef OMIM_METAL_AVAILABLE
#import <MetalKit/MetalKit.h>

#import "MetalContextFactory.h"
#endif

#import "iosOGLContextFactory.h"


@implementation EAGLView

namespace
{
// Returns DPI as exact as possible. It works for iPhone, iPad and iWatch.
double getExactDPI(double contentScaleFactor)
{
  float const iPadDPI = 132.f;
  float const iPhoneDPI = 163.f;
  float const mDPI = 160.f;

  switch (UI_USER_INTERFACE_IDIOM())
  {
    case UIUserInterfaceIdiomPhone:
      return iPhoneDPI * contentScaleFactor;
    case UIUserInterfaceIdiomPad:
      return iPadDPI * contentScaleFactor;
    default:
      return mDPI * contentScaleFactor;
  }
}
} //  namespace

+ (dp::ApiVersion)getSupportedApiVersion {
#ifdef OMIM_METAL_AVAILABLE
    id<MTLDevice> tempDevice = MTLCreateSystemDefaultDevice();
    
    if (tempDevice) {
        return dp::ApiVersion::Metal;
    }
#endif
    
    EAGLContext *tempContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    
    if (tempContext != nil) {
        return dp::ApiVersion::OpenGLES3;
    } else {
        return dp::ApiVersion::OpenGLES2;
    }
}

// You must implement this method
+ (Class)layerClass {
#ifdef OMIM_METAL_AVAILABLE
    if ([EAGLView getSupportedApiVersion] == dp::ApiVersion::Metal) {
        return [CAMetalLayer class];
    }
#endif
    
  return [CAEAGLLayer class];
}

- (instancetype)initWithEngine:(MWMMapEngine *)engine {
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        _engine = engine;
        
        [self initialize];
    }
    
    return self;
}

- (void)initialize
{
  m_presentAvailable = false;
  m_lastViewSize = CGRectZero;
  m_apiVersion = [EAGLView getSupportedApiVersion];

  // Correct retina display support in renderbuffer.
  self.contentScaleFactor = [[UIScreen mainScreen] nativeScale];
  
  if (m_apiVersion == dp::ApiVersion::Metal)
  {
#ifdef OMIM_METAL_AVAILABLE
    CAMetalLayer * layer = (CAMetalLayer *)self.layer;
    layer.device = MTLCreateSystemDefaultDevice();
    NSAssert(layer.device != NULL, @"Metal is not supported on this device");
    layer.opaque = YES;
#endif
  }
  else
  {
    CAEAGLLayer * layer = (CAEAGLLayer *)self.layer;
    layer.opaque = YES;
    layer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking : @NO,
                                 kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8};
  }
}

- (void)createDrapeEngine
{
  m2::PointU const s = [self pixelSize];
  
  if (m_apiVersion == dp::ApiVersion::Metal)
  {
#ifdef OMIM_METAL_AVAILABLE
    m_factory = make_unique_dp<MetalContextFactory>((CAMetalLayer *)self.layer, s);
#endif
  }
  else
  {
    m_factory = make_unique_dp<dp::ThreadSafeFactory>(
      new iosOGLContextFactory((CAEAGLLayer *)self.layer, m_apiVersion, m_presentAvailable));
  }
  [self createDrapeEngineWithWidth:s.x height:s.y];
}

- (void)createDrapeEngineWithWidth:(int)width height:(int)height
{
    LOG(LINFO, ("CreateDrapeEngine Started", width, height, m_apiVersion));
    CHECK(m_factory != nullptr, ());

    auto symbolsTextureDescriptions = std::vector<dp::SymbolsTextureDescription>();

    for (MWMMapSymbols *symbols in _engine.symbols) {
        auto description = dp::SymbolsTextureDescription();
        description.name = symbols.name.UTF8String;
        description.imageFilePath = symbols.imageFileUrl.path.UTF8String;
        description.mapFilePath = symbols.mapFileUrl.path.UTF8String;

        symbolsTextureDescriptions.push_back(description);
    }

    Framework::DrapeCreationParams p;
    p.m_apiVersion = m_apiVersion;
    p.m_surfaceWidth = width;
    p.m_surfaceHeight = height;
    p.m_visualScale = dp::VisualScale(getExactDPI(self.contentScaleFactor));
    p.m_symbolsTextureDescriptions = symbolsTextureDescriptions;

    MWMMapEngineFramework(_engine).CreateDrapeEngine(make_ref(m_factory), move(p));

    self->_drapeEngineCreated = YES;
    LOG(LINFO, ("CreateDrapeEngine Finished"));
}

- (m2::PointU)pixelSize
{
  CGSize const s = self.bounds.size;
  uint32_t const w = static_cast<uint32_t>(s.width * self.contentScaleFactor);
  uint32_t const h = static_cast<uint32_t>(s.height * self.contentScaleFactor);
  return m2::PointU(w, h);
}

- (void)layoutSubviews
{
  if (!CGRectEqualToRect(m_lastViewSize, self.frame))
  {
    m_lastViewSize = self.frame;
    m2::PointU const s = [self pixelSize];
    MWMMapEngineFramework(_engine).OnSize(s.x, s.y);
  }
  [super layoutSubviews];
}

- (void)deallocateNative
{
  MWMMapEngineFramework(_engine).PrepareToShutdown();
  m_factory.reset();
}

- (void)setPresentAvailable:(BOOL)available
{
  m_presentAvailable = available;
  if (m_factory != nullptr)
    m_factory->SetPresentAvailable(m_presentAvailable);
}

@end
