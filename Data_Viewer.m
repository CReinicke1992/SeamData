header = load('Seam4Chris_hdrs.mat');
hdrs = header.hdrs;

data = load('Seam4Chris.mat');
p = data.p;


figure(1);imagesc(squeeze(p(:,50,:))); colormap gray
figure(2); imagesc(squeeze(p(100,:,:))); colormap gray
figure(2); imagesc(squeeze(p(200,:,:))); colormap gray