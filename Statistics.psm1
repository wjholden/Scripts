# Basic statistics functions built on lightweight functional programming idioms.
# William John Holden (2020)
# https://github.com/wjholden/Scripts/
#
# Examples:
# > mean (0..100)
# 50
#
# > (0..20) | % { sum (0..$_) }
# (Triangular numbers; see https://oeis.org/A000217)
#
# > (0..10) | % { dbinom $_ 10 (1/6) }
# Compare to dbinom(x = 0:10, size = 10, prob = 1/6) in R.
#
# > (0..10) | % { pbinom $_ 10 (1/6) }
# Compare to pbinom(q = 0:10, size = 10, prob = 1/6) in R.
#
# > (-3,-2.5,-2,-1.5,-1,-.5,0,.5,1,1.5,2,2.5,3) | % { [System.Tuple]::Create($_, (dnorm $_), (pnorm $_))}
# Compare to data.frame(x = seq(-3,3,.5), pdf = dnorm(seq(-3,3,.5)), cdf = pnorm(seq(-3,3,.5))) in R.
# You can tune the -lower and -subdivisions parameters on pnorm for accuracy and performance.

function map([scriptblock] $f, $a) {
    return $a | ForEach-Object { $f.Invoke($_) }
}

function reduce([scriptblock] $f, $a, $i) {
    $value = $i;
    foreach($x in $a) {
        $value = Invoke-Command -ScriptBlock $f -ArgumentList @($value, $x);
    }
    return $value;
}

function seq($from, $to, $length) {
    $dx = ($to - $from) / $length;
    return map {$from + ($dx * $_)} (0..$length);
}

function sum($a) {
    return reduce {Param($x,$y) $x + $y} $a 0;
}

function mean($a) {
    return (sum $a) / $a.Length;
}

function variance($a) {
    $xbar = mean $a;
    (sum (map {[math]::Pow($_, 2)} (map {$_ - $xbar} $a))) / ($a.Length - 1);
}

function sd($a) {
    $v = variance $a;
    return [math]::Sqrt($v);
}

$memo = @{};
function choose([int]$n, [int]$r) {
    if ($r -eq 0) {
        return 1;
    } elseif ($r -eq 1) {
        return $n;
    } elseif ($r -gt $n) {
        return 0;
    } else {
        $key = [System.Tuple]::Create($n, $r);
        if (-not $memo.ContainsKey($key)) {
            $memo[$key] = (choose ($n - 1) ($r - 1)) + (choose ($n - 1) ($r));
        }
        return $memo[$key];
    }
}

function dbinom([int]$x, [int]$size, [float]$prob) {
    return (choose $size $x) * [math]::Pow($prob, $x) *
        [math]::Pow(1 - $prob, $size - $x);
}

function pbinom([int]$q, [int]$size, [float]$prob) {
    return sum(map {dbinom $_ $size $prob} (0..$q));
}

function dnorm {
    param(
        [Parameter(Mandatory=$true, Position=0)][float]$x,
        [Parameter(Mandatory=$false, Position=1)][float]$mean = 0,
        [Parameter(Mandatory=$false, Position=2)][float]$sd = 1
    )
    return (1 / ($sd * [math]::Sqrt(2 * [math]::PI))) *
        [math]::Exp(-0.5 * [math]::Pow(($x - $mean) / $sd, 2));
}

function integrate {
    param(
        [Parameter(Mandatory=$true, Position=0)][scriptblock]$f,
        [Parameter(Mandatory=$true, Position=1)][float]$lower,
        [Parameter(Mandatory=$true, Position=2)][float]$upper,
        [Parameter(Mandatory=$false, Position=3)][int]$subdivisions = 100
    )

    $dx = ($upper - $lower) / $subdivisions;
    $domain = seq $lower $upper $subdivisions;
    $range = map $f $domain;
    $trapezoids = map {param($i) $dx * ($range[$i - 1] + $range[$i]) / 2} (1..$subdivisions);
    return sum $trapezoids;
}

function pnorm {
    param(
        [Parameter(Mandatory=$true, Position=0)][float]$q,
        [Parameter(Mandatory=$false, Position=1)][float]$mean = 0,
        [Parameter(Mandatory=$false, Position=2)][float]$sd = 1,
        [Parameter(Mandatory=$false)][scriptblock]$integral = $Function:integrate,
        [Parameter(Mandatory=$false)][float]$lower = -8.127013,
        [Parameter(Mandatory=$false)][int]$subdivisions = 100
    )

    if ($q -eq $mean) {
        # I'll cheat. This one is really obvious and the numerical integration misses it.
        return .5;
    } else {
        # If this is negative it could be because the integral is being computed from high to low.
        return Invoke-Command -ScriptBlock $integral -ArgumentList @({ dnorm $_ $mean $sd }, $lower, $q, $subdivisions);
    }
}
