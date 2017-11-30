classdef AspireBipolarPoCalculator < AspirePoCalculator
%% USES ECHOES 1, 2, 4

properties
    po2
end

methods
    % override
    function calculatePo(self, compl)
        diff12 = self.normalize(calculateHip(compl));
        diff23 = self.normalize(calculateHip(compl, [2 3]));
        
        readoutGradient2 = self.getReadoutGradientDivBy(self.normalize(diff12 .* conj(diff23)), 2, size(compl, 5));
        
        self.po = self.calculateAspirePo(compl) .* readoutGradient2;
        self.po2 = self.po .* readoutGradient2;
        self.storage.write(self.po, 'po');
        self.storage.write(self.po2, 'po2');
    end
    
    % override
    function compl = removePo(self, compl)
        nEchoes = size(compl,4);
        for iEco = 1:nEchoes
            if mod(iEco, 2) == 1
                compl(:,:,:,iEco,:) = squeeze(compl(:,:,:,iEco,:)) .* squeeze(conj(self.po));
            else
                compl(:,:,:,iEco,:) = squeeze(compl(:,:,:,iEco,:)) .* squeeze(conj(self.po2));
            end
        end
    end
    
    % override
    function smoothPo(self, weight)
        self.po = self.smoother.smooth(self.po, weight);
        self.po2 = self.smoother.smooth(self.po2, weight);
    end
    
    % override
    function removeMagPo(self)
        self.po = self.removeMag(self.po);
        self.po2 = self.removeMag(self.po2);
        self.storage.write(self.po, 'poSmooth');
        self.storage.write(self.po2, 'po2Smooth');
    end
    
    
    function readoutGradient = getReadoutGradientDivBy(self, gradient4, div, nChannels)
        self.storage.write(gradient4, 'gradient4');

        sizeArr = size(gradient4);
        shift = 10;
        diffMap = self.normalize(gradient4((1+shift):end,:,:,:) .* conj(gradient4(1:(end-shift),:,:,:)));
        self.storage.write(diffMap, 'diffMap');

        diff = sum(diffMap(:));
        gradient = angle(diff) / div / shift;

        readoutDim = 1;
        rMin = -sizeArr(readoutDim)/2;
        rValues = rMin:(rMin + sizeArr(readoutDim) - 1);
        
        repSizes = sizeArr; repSizes(readoutDim) = 1;
        
        readoutGradient = repmat(rValues, repSizes) * gradient;
        readoutGradient = reshape(readoutGradient, sizeArr);
        readoutGradient = exp(1i * readoutGradient);
        self.storage.write(readoutGradient, 'readoutGradient');
        
        readoutGradient = repmat(readoutGradient, [1 1 1 nChannels]);
    end
end
    
end
