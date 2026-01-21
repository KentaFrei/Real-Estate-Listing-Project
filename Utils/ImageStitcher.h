// ImageStitcher.h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, StitcherStatus) {
    StitcherStatusSuccess,
    StitcherStatusErrorInput,
    StitcherStatusErrorStitching
};

@interface ImageStitcher : NSObject

/// Soglia di confidenza per il panorama (default: 0.7)
/// Valori più alti richiedono maggiore sovrapposizione tra le immagini
@property (nonatomic, assign) double panoConfidenceThresh;

/// Forza del blending (default: 8.0)
/// Valori: <5 = Low (3 bands), 5-10 = Medium (7 bands), >10 = High (12 bands)
@property (nonatomic, assign) double blendingStrength;

/// Abilita la correzione dell'onda/ondulazione (default: YES)
@property (nonatomic, assign) BOOL waveCorrection;

- (instancetype)init;

/// Esegue lo stitching delle immagini fornite
/// @param images Array di UIImage da combinare (minimo 2)
/// @param error Puntatore per ricevere eventuali errori
/// @return UIImage del panorama risultante, o nil in caso di errore
- (nullable UIImage *)stitchImages:(NSArray<UIImage *> *)images
                             error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END





