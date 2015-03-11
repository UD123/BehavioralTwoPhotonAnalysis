function MOV=adademo
% ADADEMO  AdaBoost demo
%  ADADEMO runs AdaBoost on a simple two dimensional classification
%  problem.

% Written by Andrea Vedaldi - 2006
% http://vision.ucla.edu/~vedaldi

do_movie = nargout > 0 ;

% --------------------------------------------------------------------
%                                                     Generate dataset
% --------------------------------------------------------------------
% Data are just two clouds of 2-D points. Positive (y=+1) examples are
% normally distributed. Negative (y=-1) examples are distributed
% all around. Variables:
%
% Np = number of positive examples
% Nm = number of negative examples
% N  = number of total examples
% Xp = positive examples (Np 2-D 'red' points)
% Xm = negative examples (Nm 2-D 'green' points)

Np = 100 ;
Nm = 200 ;
N  = Np + Nm ;

Xp = 0.75*randn(2,Np) ;
r  = randn(1,Nm) + 4 ;
th = linspace(0,2*pi,Nm) ;
Xm = [r.*cos(th);r.*sin(th)] ;

% --------------------------------------------------------------------
%                                                     Weak classifiers
% --------------------------------------------------------------------
% Weak classifiers are just 2 dimensional linear classifiers (half
% planes). They are parametrized by a rotation TH and a radius R,
% with the convention that the plane passes by the point RV and is
% orthogonal to the vector RV, where V=[cos(TH);sin(TH)].
%
% thr   = range of rotations
% rr    = range of radii
% th,r  = rotations and radii
% h_set = universe of weak classifiers
% wce   = weak classifiers weighted classification errors

% set of weak classifiers
thr    = linspace(0,2*pi,100) ;
rr     = linspace(-5,5,100) ;
[th,r] = meshgrid(thr,rr) ;
h_set  = [th(:)';r(:)'] ;
wce   = zeros(1,size(h_set,2)) ;

% --------------------------------------------------------------------
%                                                       Initial values
% --------------------------------------------------------------------

% T     = total numvber of rounds
% coeff = coefficients of weak classifiers added so far
% H     = weak classifiers selected so far
% wgtp  = weights of positive examples
% wgtm  = weights of negative examples
% Hp    = strong classifier H evaluated on positive examples
% Hm    = strong classifier H evaluated on negative examples

T = 100 ;

wgtp = ones(1,Np) / N ;
wgtm = ones(1,Nm) / N ;
Hp   = zeros(1,Np) ;
Hm   = zeros(1,Nm) ;

coeff = zeros(1,T) ;
H     = zeros(2,T) ;

% The following variables are used only for visualization:
%
% ce    = strong classifier classification errror (historic)
% ec    = exponential criterion (historic)
% xr,yr = range of x,y coordinates (for plots)
% x,y   = grid of x,y coordiantes (for plots)
% X     = 2-D points corresp. to x,y
% H_    = strong classifeirs evaluated on x,y

ce     = zeros(1,T) ;
ec     = zeros(1,T) ;
xr     = linspace(-5,5,100);
yr     = xr ;
[x,y]  = meshgrid(xr,yr);
X      = [x(:)';y(:)'] ;
H_     = zeros(100,100) ;


% --------------------------------------------------------------------
%                                                                Boost
% --------------------------------------------------------------------

for t=1:T
  
  % Evaluate weighted errors of all weak classifiers
  i=1 ;
  for h=h_set
    hp = weak(h,Xp) ;
    hm = weak(h,Xm) ;    
    E(i) = sum((hp ~= +1) .* wgtp) + sum((hm ~= -1) .* wgtm) ;
    i=i+1 ;
  end
    
  % Select weak classifier with smaller classif. error
  [drop,best] = min(E) ;
  H(:,t) = h_set(:,best) ;
  
  % Compute coefficient of last weak classifier
  err = E(best) ;
  if(err>.5)
    warning('Error > .5? Stopping.');
    break;
  end
  coeff(t) = 0.5 * log( (1-err)/err ) ;
  
  % Update strong classifier and example weights
  hp   = coeff(t) * weak(H(:,t),Xp) ;
  hm   = coeff(t) * weak(H(:,t),Xm) ;
  Hp   = Hp + hp ;
  Hm   = Hm + hm ;  
  wgtp = wgtp .* exp(- hp) ;
  wgtm = wgtm .* exp(+ hm) ;
  Z    = sum(wgtp) + sum(wgtm) ;
  wgtp = wgtp/Z ;
  wgtm = wgtm/Z ;

  
  % ------------------------------------------------------------------
  % Plots
  % ------------------------------------------------------------------
  
  % Update exponential criterion and classific. error
  ec(t) = (sum(exp(-Hp))    +sum(exp(Hm))     ) / N ;
  ce(t) = (sum(sign(Hp)~=+1)+sum(sign(Hm)~=-1)) / N ;

  H_ = H_ + reshape(coeff(t)*weak(H(:,t),X),100,100) ;
  
  figure(100) ; clf ; 

  [drop,permp] =  sort(-wgtp) ;
  [drop,permm] =  sort(-wgtm) ;
  
  subplot(2,2,1) ; colormap gray; 
  hold on ; 
  plotpoint(Xp,'r.') ;
  plotpoint(Xm,'g.') ;
  plotpoint(Xp(:,permp(1:10)),'o') ;
  plotpoint(Xm(:,permm(1:10)),'o') ;
  axis([-5 5 -5 5]) ;
  for h = H(:,1:t)
     v  = [cos(h(1));sin(h(1))] ;
     u  = [-v(2);v(1)] ;
     z0 = h(2)*v + 10*u ;
     z1 = h(2)*v - 10*u ;
     plot([z0(1) z1(1)],[z0(2) z1(2)]);
  end
  title('Weak classifiers') ;
  
  subplot(2,2,2) ; hold on ;  
  plot(ec(1:t),'r-','LineWidth',2) ;
  plot(ce(1:t),'g-','LineWidth',2) ;
  xlim([1 T]);
  legend('Exp. crit.','Class. err.') ;
  title('Exp. crit. and class. err.') ;
  
  
  subplot(2,2,3) ;
  axis([-5 5 -5 5]) ;
  imagesc(xr,yr,H_) ;
  set(gca,'YDir','normal') ;
  title('Function H(x)') ;
  
  subplot(2,2,4) ; hold on ;
  axis([-5 5 -5 5]) ;
  imagesc(xr,yr,H_>0) ; 
  plotpoint(Xp,'r.') ;
  plotpoint(Xm,'g.') ;
  title('Function sign H(x)') ;

  drawnow ;
  
  if do_movie
    MOV(t) = getframe(gcf) ;
  end
end

% --------------------------------------------------------------------
function C = weak(h,X)
% --------------------------------------------------------------------
% Calculate weak lerner
c = cos(h(1)) ;
s = sin(h(1)) ;
C = sign([c s]*X-h(2)) ;

% --------------------------------------------------------------------
function h = plotpoint(X,varargin)
% --------------------------------------------------------------------
h = plot(X(1,:),X(2,:),varargin{:}) ;
