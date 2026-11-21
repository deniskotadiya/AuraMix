import os, numpy as np, wave as wavefile
base='/mnt/data/auramix_flutter/assets/audio'; os.makedirs(base,exist_ok=True)
sr=22050; dur=8; n=sr*dur; t=np.arange(n)/sr; rng=np.random.default_rng(42)
def norm(x):
 x=np.asarray(x,dtype=np.float32); x=x/(np.max(np.abs(x))+1e-8)*.72
 k=int(sr*.25); a=x[:k].copy(); b=x[-k:].copy(); w=np.linspace(0,1,k); x[:k]=a*(1-w)+b*w; x[-k:]=x[:k]
 return np.clip(x,-1,1)
def filt(noise,alpha):
 y=np.zeros_like(noise); y[0]=noise[0]
 for i in range(1,len(noise)): y[i]=alpha*y[i-1]+(1-alpha)*noise[i]
 return y
noise=rng.normal(0,1,n)
rain=(noise*.25+(noise-filt(noise,.94))*.9)*(.75+.22*np.sin(2*np.pi*.13*t)+.08*np.sin(2*np.pi*.31*t))
pink=filt(noise,.985); wave=(.20+.80*(.5+.5*np.sin(2*np.pi*.075*t+.25*np.sin(2*np.pi*.02*t))))**2; ocean=pink*wave
forest=filt(noise,.97)*.13
for start in np.arange(.6,7.7,.83):
 freq=2200+rng.uniform(-500,900); length=.13+rng.uniform(0,.1); idx=(t>=start)&(t<start+length); tt=t[idx]-start; env=np.sin(np.pi*tt/length)**2
 forest[idx]+=.16*env*np.sin(2*np.pi*(freq+400*tt)*tt)
fire=filt(noise,.88)*.20
for _ in range(65):
 pos=rng.integers(0,n); length=rng.integers(60,500); end=min(n,pos+length); tt=np.arange(end-pos)/sr
 fire[pos:end]+=rng.uniform(.25,.75)*np.exp(-tt*18)*rng.normal(0,.6,end-pos)
wind=filt(noise,.996)*(.25+.7*(.5+.5*np.sin(2*np.pi*.04*t)))*.5
birds=filt(noise,.98)*.04
for start in np.arange(.25,7.6,.53):
 length=rng.uniform(.08,.18); idx=(t>=start)&(t<start+length); tt=t[idx]-start; f0=rng.uniform(1500,3400); sweep=rng.uniform(-1300,1500)
 birds[idx]+=.22*np.sin(2*np.pi*(f0*tt+sweep*tt**2))*np.sin(np.pi*tt/length)**2
white=noise*.28; brown=filt(noise,.999)*.4; pink=filt(noise,.96)*.27
cafe=filt(noise,.94)*.1+noise*.06
for _ in range(30):
 pos=rng.integers(0,n); length=rng.integers(800,8000); end=min(n,pos+length); tt=np.arange(end-pos)/sr
 cafe[pos:end]+=rng.uniform(.06,.20)*np.sin(2*np.pi*rng.uniform(300,1500)*tt)*np.exp(-tt*4)
assets={'rain.wav':rain,'ocean.wav':ocean,'forest.wav':forest,'fireplace.wav':fire,'wind.wav':wind,'birds.wav':birds,'white_noise.wav':white,'brown_noise.wav':brown,'pink_noise.wav':pink,'cafe.wav':cafe}
for name,data in assets.items():
 data=norm(data)
 with wavefile.open(os.path.join(base,name),'wb') as wf:
  wf.setnchannels(1); wf.setsampwidth(2); wf.setframerate(sr); wf.writeframes((data*32767).astype(np.int16).tobytes())
print('generated',list(assets))
