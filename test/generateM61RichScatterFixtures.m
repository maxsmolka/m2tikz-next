function paths = generateM61RichScatterFixtures(outputDirectory)
%GENERATEM61RICHSCATTERFIXTURES Write six standalone synthetic TeX fixtures.
    root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
    if nargin<1,outputDirectory=fullfile(root,'.audit','m61-rich-scatter-tex');end
    if exist(outputDirectory,'dir')~=7,mkdir(outputDirectory);end
    specs={ ...
        'constant-size-constant-rgb','constant_rgb','constant',false; ...
        'varying-size-constant-rgb','constant_rgb','per_point',false; ...
        'constant-size-point-rgb','per_point_rgb','constant',false; ...
        'varying-size-point-rgb','per_point_rgb','per_point',false; ...
        'scalar-mapped','scalar_mapped','constant',false; ...
        'scalar-mapped-colorbar','scalar_mapped','per_point',true};
    paths=cell(1,size(specs,1));
    for k=1:size(specs,1)
        ir=fixture(specs{k,2},specs{k,3},specs{k,4});
        paths{k}=fullfile(outputDirectory,[specs{k,1} '.tex']);
        m2t.internal.writeTextFile(paths{k},m2t2.render.renderPgfplots(ir,true));
    end
    paths{end+1}=writeFixture(outputDirectory,'multiple-scatter',mixedFixture('scatter'));
    paths{end+1}=writeFixture(outputDirectory,'scatter-line',mixedFixture('line'));
    paths{end+1}=writeFixture(outputDirectory,'scatter-image',mixedFixture('image'));
end

function ir=fixture(colorMode,sizeMode,withColorbar)
    s=m2t2.ir.makeScatterSeries();s.x=[1 2 3 4];s.y=[1 3 2 4];
    s.color=[.15 .35 .75];s.edgeColor=s.color;
    if strcmp(sizeMode,'per_point'),s.sizeMode='per_point';s.markerSize=[4 6 8 10];end
    if strcmp(colorMode,'per_point_rgb')
        s.colorMode=colorMode;s.colorData=[.8 .1 .1;.1 .65 .2;.1 .25 .85;.7 .2 .75];
        s.edgeMode='none';s.faceMode='data';
    elseif strcmp(colorMode,'scalar_mapped')
        s.colorMode=colorMode;s.colorData=[0 .35 .7 1];s.edgeMode='constant';
        s.edgeColor=[.1 .1 .1];s.faceMode='data';
    end
    a=m2t2.ir.makeAxes();a.xlim=[.5 4.5];a.ylim=[.5 4.5];a.series={s};
    a.colorMapping.limits=[0 1];t=linspace(0,1,16)';
    a.colorMapping.colormap=[0.12+0.78*t,0.18+0.62*sin(pi*t),0.82-0.70*t];
    ir=m2t2.ir.makeFigure({a});ir.size=[320 220];
    if withColorbar,cb=m2t2.ir.makeColorbar();cb.limits=[0 1];ir.elements={cb};end
    m2t2.ir.validate(ir);
end

function ir=mixedFixture(kind)
    ir=fixture('scalar_mapped','per_point',false);a=ir.axes{1};
    switch kind
        case 'scatter'
            second=m2t2.ir.makeScatterSeries();second.id='axes-1-series-2';
            second.x=[1 2 3 4];second.y=[4 2.5 3.5 1.5];second.color=[.75 .15 .2];
            second.edgeColor=second.color;a.series{end+1}=second;
        case 'line'
            line=m2t2.ir.makeLineSeries();line.id='axes-1-series-2';
            line.x=[1 2 3 4];line.y=[1.5 2.2 2.8 3.4];line.color=[.15 .15 .15];
            a.series{end+1}=line;
        case 'image'
            image=m2t2.ir.makeImageSeries();image.id='axes-1-series-2';
            image.x=[1 4];image.y=[1 4];image.cdata=[0 .4;.65 1];
            a.series=[{image},a.series];
    end
    ir.axes={a};m2t2.ir.validate(ir);
end

function path=writeFixture(directory,name,ir)
    path=fullfile(directory,[name '.tex']);
    m2t.internal.writeTextFile(path,m2t2.render.renderPgfplots(ir,true));
end
