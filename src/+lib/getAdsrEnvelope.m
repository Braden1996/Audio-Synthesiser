% Router to distribute our callbacks appropriately. 
function envelope = adsr(a,d,s,r,len,overshoot)
    % Normalise
    adsrNorm = a + d + s + r;
    a = a / adsrNorm;
    d = d / adsrNorm;
    s = s / adsrNorm;
    r = r / adsrNorm;

    samplesADSR = [a,d,s,r]*len;

    if overshoot > 1
       sustainLevel = 1/overshoot;
       overshoot = 1;
    else
       sustainLevel = 1;
    end
    
    % To deal with rounding errors, we calculate rN differently.
    aN = floor(samplesADSR(1));
    dN = floor(samplesADSR(2));
    sN = floor(samplesADSR(3));
    rN = len - aN - dN - sN;

    A = linspace(0, overshoot, aN);
    D = linspace(overshoot, sustainLevel, dN);
    S = linspace(sustainLevel, sustainLevel, sN);
    R = linspace(sustainLevel, 0, rN);
    envelope = [A,D,S,R];