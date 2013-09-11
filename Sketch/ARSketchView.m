
#import "ARSketchView.h"
#import <QuartzCore/QuartzCore.h>


@interface ARBezierPath : UIBezierPath
@property (nonatomic,assign) NSTimeInterval timelapse;
@end

@implementation ARBezierPath
@end


@implementation ARSketchView
{
    NSMutableArray *finishedPaths;
    NSMutableDictionary *ongoingPath;
}


-(void) awakeFromNib {
    [self setup];
}


-(void) setup {
    ongoingPath = [NSMutableDictionary dictionary];
    finishedPaths = [NSMutableArray array];
}


- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self){
        [self setup];
    }
    return self;
}


- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches)
    {
        ARBezierPath *path = [ARBezierPath new];
        CGPoint point = [touch locationInView:self];
        [path moveToPoint:point];
        path.timelapse = [NSDate timeIntervalSinceReferenceDate];
        
        ongoingPath[@((int)touch)] = path;
    }
}


- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches)
    {
        NSNumber *key = @((int)touch);
        ARBezierPath *path = ongoingPath[key];
        
        if (path){
            CGPoint point = [touch locationInView:self];
            [path addLineToPoint:point];
        }
    }
    
    // repaint to show the new line added
    [self setNeedsDisplay];
}


- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{    
    for (UITouch *touch in touches)
    {
        NSNumber *key = @((int)touch);
        ARBezierPath *path = ongoingPath[key];
        
        if (path){
            CGPoint point = [touch locationInView:self];
            [path addLineToPoint:point];
            path.timelapse = [NSDate timeIntervalSinceReferenceDate] - path.timelapse;
        }
        
        [ongoingPath removeObjectForKey:key];
        [finishedPaths addObject:path];
    }
    
    [self setNeedsDisplay];
}


- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}


- (void) drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    for (ARBezierPath *path in finishedPaths){
        [path stroke];
    }
    
    for (ARBezierPath *path in [ongoingPath allValues]){
        [path stroke];
    }
    
}


#pragma mark - 


- (IBAction) clear
{
    [CATransaction begin];
    finishedPaths = [NSMutableArray array];
    ongoingPath = [NSMutableDictionary dictionary];
    for (CALayer *layer in self.layer.sublayers){
        [layer removeFromSuperlayer];
    }
    [CATransaction commit];
    [self setNeedsDisplay];
}


- (IBAction) replay 
{
    UIView *preview = [[UIView alloc] initWithFrame:self.frame];
    preview.backgroundColor = [UIColor whiteColor];
    [self addSubview:preview];
    
    NSTimeInterval total = 0.0;
    
    for (ARBezierPath *path in finishedPaths)
    {        
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = [path CGPath];
        shapeLayer.strokeColor = [[UIColor blackColor] CGColor];
        shapeLayer.fillColor = nil;
        shapeLayer.lineWidth = 1.0f;
        shapeLayer.lineJoin = kCALineJoinBevel;
        
        CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        pathAnimation.duration = path.timelapse;
        pathAnimation.fromValue = @(0.0f);
        pathAnimation.toValue = @(1.0f);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, total * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [shapeLayer addAnimation:pathAnimation forKey:@"strokeEnd"];
            [preview.layer addSublayer:shapeLayer];
        });
        
        total += path.timelapse;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, total * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [preview removeFromSuperview];
    });
    
}


@end
