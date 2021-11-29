## Chart-4

Stacktrace:


```
java.lang.NullPointerException
	[1] at org.jfree.chart.plot.XYPlot.getDataRange(XYPlot.java:4493) 
	[2] at org.jfree.chart.axis.NumberAxis.autoAdjustRange(NumberAxis.java:434)
	[3] at org.jfree.chart.axis.NumberAxis.configure(NumberAxis.java:417)
	[4] at org.jfree.chart.plot.XYPlot.configureDomainAxes(XYPlot.java:972)
	[5] at org.jfree.chart.plot.XYPlot.setRenderer(XYPlot.java:1644)
	[6] at org.jfree.chart.plot.XYPlot.setRenderer(XYPlot.java:1620)
	[7] at org.jfree.chart.plot.XYPlot.setRenderer(XYPlot.java:1607)
```


Frames 7 and 6 point to a single line method. So, it should not be a big issue for the search process to execute them. However, the first challenges appear in frame 5. This frame points to the following method:

```java
public void setRenderer(int index, XYItemRenderer renderer,
                            boolean notify) {
        XYItemRenderer existing = getRenderer(index); // safe
        if (existing != null) {
            existing.removeChangeListener(this); // safe
        }
        this.renderers.set(index, renderer);
        if (renderer != null) {
            renderer.setPlot(this); 
            renderer.addChangeListener(this); // safe
        }
        configureDomainAxes(); // -> line 1644
        configureRangeAxes();
        if (notify) {
            fireChangeEvent();
        }
    }
```


frame 1 is in the target class. This frame points to a very long method:

```java


       [...]

        // iterate through the datasets that map to the axis and get the union
        // of the ranges.
        Iterator iterator = mappedDatasets.iterator();
        while (iterator.hasNext()) {
            XYDataset d = (XYDataset) iterator.next();
            if (d != null) {
                XYItemRenderer r = getRendererForDataset(d);
                if (isDomainAxis) {
                    if (r != null) {
                        result = Range.combine(result, r.findDomainBounds(d)); // not safe [I]
                    }
                    else {
                        result = Range.combine(result,
                                DatasetUtilities.findDomainBounds(d));
                    }
                }
                else {
                    if (r != null) {
                        result = Range.combine(result, r.findRangeBounds(d)); // not safe [I]
                    }
                    else {
                        result = Range.combine(result,
                                DatasetUtilities.findRangeBounds(d)); // not safe [I]
                    }
                }
                
                    Collection c = r.getAnnotations(); // target line
                    ...}
```

[I]

method combine is:
```java
    public static Range combine(Range range1, Range range2) {
        if (range1 == null) {
            return range2;
        }
        else {
            if (range2 == null) {
                return range1;
            }
            else {
                double l = Math.min(range1.getLowerBound(),
                        range2.getLowerBound());
                double u = Math.max(range1.getUpperBound(),
                        range2.getUpperBound());
                return new Range(l, u);
            }
        }
    }
```

as we can see, it is oossible that this method calls ` return new Range(l, u);`
This constructor can throw an exception:
```java
    public Range(double lower, double upper) {
        if (lower > upper) {
            String msg = "Range(double, double): require lower (" + lower
                + ") <= upper (" + upper + ").";
            throw new IllegalArgumentException(msg);
        }
        this.lower = lower;
        this.upper = upper;
    }
```

method combin is called multiple times after the last control dependent node. the search process does not have any guidance to pass this exception without using BBC.


## Math-3
stacktrace:
```
java.lang.ArrayIndexOutOfBoundsException: 1
	at org.apache.commons.math3.util.MathArrays.linearCombination(MathArrays.java:846)
```

target class: org.apache.commons.math3.util.MathArrays


This stacktrace only has one method involved (linearCombination):

```java
public static double linearCombination(final double[] a, final double[] b)
        throws DimensionMismatchException {
        final int len = a.length;
        if (len != b.length) {
            throw new DimensionMismatchException(len, b.length);
        }

            // Revert to scalar multiplication.

        final double[] prodHigh = new double[len];
        double prodLowSum = 0;

        for (int i = 0; i < len; i++) {
            final double ai = a[i];
            final double ca = SPLIT_FACTOR * ai;
            final double aHigh = ca - (ca - ai);
            final double aLow = ai - aHigh;

            final double bi = b[i];
            final double cb = SPLIT_FACTOR * bi;
            final double bHigh = cb - (cb - bi);
            final double bLow = bi - bHigh;
            prodHigh[i] = ai * bi;
            final double prodLow = aLow * bLow - (((prodHigh[i] -
                                                    aHigh * bHigh) -
                                                   aLow * bHigh) -
                                                  aHigh * bLow);
            prodLowSum += prodLow;
        }


        final double prodHighCur = prodHigh[0];
        double prodHighNext = prodHigh[1]; // target line
        double sHighPrev = prodHighCur + prodHighNext;
        double sPrime = sHighPrev - prodHighNext;
        double sLowSum = (prodHighNext - (sHighPrev - sPrime)) + (prodHighCur - sPrime);

        final int lenMinusOne = len - 1;
        for (int i = 1; i < lenMinusOne; i++) {
            prodHighNext = prodHigh[i + 1];
            final double sHighCur = sHighPrev + prodHighNext;
            sPrime = sHighCur - prodHighNext;
            sLowSum += (prodHighNext - (sHighCur - sPrime)) + (sHighPrev - sPrime);
            sHighPrev = sHighCur;
        }

        double result = sHighPrev + (prodLowSum + sLowSum);

        if (Double.isNaN(result)) {
            // either we have split infinite numbers or some coefficients were NaNs,
            // just rely on the naive implementation and let IEEE754 handle this
            result = 0;
            for (int i = 0; i < len; ++i) {
                result += a[i] * b[i];
            }
        }

        return result;
    }

```

This exception can be triggered only in one specific case where the input parameters (a and b) both has size 1.

If a and b does not have the same size this method throw an explicit branch. Hence, approach level and branch distance can guide the search process to make sure that the generated tests that assign arrays with the same sizes to a and b has higher fitness.
However, since the explicit branch was the only control depdendent branch for the target lines. the search process does not have any guidance to cover the next lines (including the target line from the stacktrace). Assume that test T1 instantiate a and b with size 0. Then, this method throws ArrayIndexOutOfBoundsException in one line before the target line. This implicit branch will be hidden from approach level and branch distance. By adding BBC, the search process can differentiate these two tests and help the search process to generate tests that can cover next lines more often. By having more tests that can cover the target line, the search process ahs higher chance to execute the target line and thereby find the ArrayIndexOutOfBoundsException in this line. 

DynaMOSA managed to detect this fault only 9/30. However, BBC-0.5 captured this fault 23/30 times. 
