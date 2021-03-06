#import <Foundation/Foundation.h>
#import "CPPlot.h"
#import "CPDefinitions.h"

///	@file

@class CPLineStyle;
@class CPMutableNumericData;
@class CPNumericData;
@class CPFill;
@class CPPlotRange;
@class CPColor;
@class CPBarPlot;
@class CPTextLayer;
@class CPTextStyle;

/// @name Binding Identifiers
/// @{
extern NSString * const CPBarPlotBindingBarLocations;
extern NSString * const CPBarPlotBindingBarTips;
extern NSString * const CPBarPlotBindingBarBases;
///	@}

/**	@brief Enumeration of bar plot data source field types
 **/
typedef enum _CPBarPlotField {
    CPBarPlotFieldBarLocation = 2,  ///< Bar location on independent coordinate axis.
    CPBarPlotFieldBarTip   	  = 3,	///< Bar tip value.
    CPBarPlotFieldBarBase     = 4	///< Bar base (if baseValue is nil.)
} CPBarPlotField;

#pragma mark -

/**	@brief A bar plot data source.
 **/
@protocol CPBarPlotDataSource <CPPlotDataSource> 
@optional 

/**	@brief Gets a bar fill for the given bar plot. This method is optional.
 *	@param barPlot The bar plot.
 *	@param index The data index of interest.
 *	@return The bar fill for the point with the given index.
 **/
-(CPFill *)barFillForBarPlot:(CPBarPlot *)barPlot recordIndex:(NSUInteger)index; 

/** @brief Gets a bar label for the given bar plot. This method is no longer used.
 *	@param barPlot The bar plot.
 *	@param index The data index of interest.
 *	@return The bar label for the point with the given index.
 *  If you return nil, the default bar label will be used. If you return an instance of NSNull,
 *  no label will be shown for the index in question.
 *	@deprecated This method has been replaced by the CPPlotDataSource::dataLabelForPlot:recordIndex: method and is no longer used.
 **/
-(CPTextLayer *)barLabelForBarPlot:(CPBarPlot *)barPlot recordIndex:(NSUInteger)index;

@end 

#pragma mark -

/**	@brief Bar plot delegate.
 **/
@protocol CPBarPlotDelegate <NSObject>

@optional

// @name Point selection
/// @{

/**	@brief Informs delegate that a point was touched.
 *	@param plot The scatter plot.
 *	@param index Index of touched point
 **/
-(void)barPlot:(CPBarPlot *)plot barWasSelectedAtRecordIndex:(NSUInteger)index;

///	@}

@end

#pragma mark -

@interface CPBarPlot : CPPlot {
	@private
    CPLineStyle *lineStyle;
    CPFill *fill;
    NSDecimal barWidth;
    NSDecimal barOffset;
    CGFloat barCornerRadius;
    NSDecimal baseValue;	
    BOOL barsAreHorizontal;
    BOOL barBasesVary;
    BOOL barWidthsAreInViewCoordinates;
    CPPlotRange *plotRange;
} 

@property (nonatomic, readwrite, assign) BOOL barWidthsAreInViewCoordinates;
@property (nonatomic, readwrite, assign) NSDecimal barWidth;
@property (nonatomic, readwrite, assign) NSDecimal barOffset;
@property (nonatomic, readwrite, assign) CGFloat barCornerRadius;
@property (nonatomic, readwrite, copy) CPLineStyle *lineStyle;
@property (nonatomic, readwrite, copy) CPFill *fill;
@property (nonatomic, readwrite, assign) BOOL barsAreHorizontal;
@property (nonatomic, readwrite, assign) NSDecimal baseValue;
@property (nonatomic, readwrite, assign) BOOL barBasesVary;
@property (nonatomic, readwrite, copy) CPPlotRange *plotRange;
@property (nonatomic, readwrite, assign) CGFloat barLabelOffset;
@property (nonatomic, readwrite, copy) CPTextStyle *barLabelTextStyle;

/// @name Factory Methods
/// @{
+(CPBarPlot *)tubularBarPlotWithColor:(CPColor *)color horizontalBars:(BOOL)horizontal;
///	@}

@end
