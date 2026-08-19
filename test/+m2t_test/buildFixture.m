function fixture = buildFixture(id)
%BUILDFIXTURE Construct one deterministic, generic cross-runtime fixture.
    fixture=struct('figures',[],'primary',[],'exportOptions',{{}},'mode','single');
    switch id
        case 'F01'
            [fig,ax]=baseFigure();plot(ax,0:4,[0 1 4 9 16]);labels(ax,'Input','Response','Line');
        case 'F02'
            [fig,ax]=baseFigure();plot(ax,0:4,[0 1 4 9 16]);hold(ax,'on');plot(ax,0:4,[0 1 2 3 4],'--');
        case 'F03'
            [fig,ax]=baseFigure();scatter(ax,1:5,[1 4 2 5 3],36,[.2 .4 .7],'o');
        case 'F04'
            [fig,ax]=baseFigure();errorbar(ax,1:4,[2 3 2.5 4],[.2 .3 .2 .4],'-o');
        case 'F05'
            [fig,ax]=baseFigure();errorbar(ax,1:4,[2 3 2.5 4],[.1 .2 .1 .2],[.3 .4 .2 .5],'-o');
        case 'F06'
            [fig,ax]=baseFigure();plot(ax,1:5,[1 2 3 4 5]);hold(ax,'on');scatter(ax,1:5,[1.1 1.9 3.2 3.8 5.1],24,'o');
        case 'F07'
            [fig,ax]=baseFigure();plot(ax,1:4,[1 2 3 4]);hold(ax,'on');errorbar(ax,1:4,[1.2 2.1 2.8 4.1],.15*ones(1,4));
        case 'F08'
            [fig,ax]=baseFigure();plot(ax,1:4,[1 2 1 3],'DisplayName','Measured');hold(ax,'on');plot(ax,1:4,[1 1.5 2 2.5],'DisplayName','Reference');legend(ax,'show');
        case 'F09'
            [fig,ax]=baseFigure();plot(ax,0:3,[0 1 4 9]);set(ax,'XTick',[0 1.5 3],'XTickLabel',{'zero','middle','three'});
        case 'F10'
            [fig,ax]=baseFigure();semilogx(ax,[1 10 100],[1 2 4]);set(ax,'YScale','log');
        case 'F11'
            [fig,ax]=baseFigure();plot(ax,1:4,[1 3 2 4]);set(ax,'XDir','reverse','YDir','reverse');
        case 'F12'
            fig=figure('Visible','off');ax=axes('Parent',fig,'Position',[.15 .2 .7 .65]);plot(ax,1:3,[1 3 2]);
        case 'F13'
            fig=figure('Visible','off');a1=subplot(1,2,1,'Parent',fig);plot(a1,1:3,[1 2 1]);a2=subplot(1,2,2,'Parent',fig);plot(a2,1:3,[2 1 3]);
        case 'F14'
            fig=figure('Visible','off');for k=1:4,ax=subplot(2,2,k,'Parent',fig);plot(ax,1:3,[k k+1 k]);end
        case 'F15'
            [fig,ax]=baseFigure();imagesc(ax,[1 2;3 4]);colorbar(ax);
        case 'F16'
            [fig,ax]=baseFigure();imagesc(ax,[1 2;3 4]);colorbar(ax,'southoutside');
        case 'F17'
            fig=figure('Visible','off');a1=subplot(1,2,1,'Parent',fig);plot(a1,1:3,[1 2 1]);a2=subplot(1,2,2,'Parent',fig);plot(a2,1:3,[2 1 2]);
        case 'F18'
            [fig,ax]=baseFigure();imagesc(ax,[1 2 3;4 5 6]);
        case 'F19'
            [fig,ax]=baseFigure();imagesc(ax,[10 20 30],[100 200],[1 2 3;4 5 6]);
        case 'F20'
            [fig,ax]=baseFigure();imagesc(ax,[1 2;3 4]);set(ax,'YDir','normal');
        case 'F21'
            [fig,ax]=baseFigure();imagesc(ax,[1 2;3 4]);set(ax,'CLim',[-2 7]);
        case 'F22'
            [fig,ax]=baseFigure();imagesc(ax,[1 2;3 4]);colormap(ax,[0 0 .5;.2 .8 .7;1 .9 .2;.7 0 0]);
        case 'F23'
            [fig,ax]=baseFigure();plot(ax,0:4,[0 1 4 9 16]);fixture.exportOptions={'Profile','publication','Width','single-column'};
        case 'F24'
            [fig1,ax1]=baseFigure();plot(ax1,1:3,[1 2 1]);[fig2,ax2]=baseFigure();scatter(ax2,1:3,[2 1 3],24,'o');
            fixture.figures=[fig1 fig2];fixture.primary=fig1;fixture.mode='set';return
        case 'F25'
            [fig,ax]=baseFigure();imagesc(ax,peaks(65));colorbar(ax);fixture.exportOptions={'ImageBackend','hybrid'};
        case 'F26'
            [fig,ax]=baseFigure();imagesc(ax,peaks(65));fixture.exportOptions={'ImageBackend','auto'};
        otherwise
            error('M2T_TEST:FIXTURE_UNKNOWN','Unknown fixture ID: %s.',id);
    end
    fixture.figures=fig;fixture.primary=fig;
end

function [fig,ax]=baseFigure()
    fig=figure('Visible','off');ax=axes('Parent',fig);
end
function labels(ax,x,y,t),xlabel(ax,x);ylabel(ax,y);title(ax,t);end
