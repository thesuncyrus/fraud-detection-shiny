"""Render verified aggregate results; never synthesize predictions from metrics."""
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import pandas as pd
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'results/figures';OUT.mkdir(parents=True,exist_ok=True)
plt.rcParams.update({'font.family':'DejaVu Sans','font.size':11,'svg.fonttype':'none',
 'axes.spines.top':False,'axes.spines.right':False,'figure.facecolor':'#faf9f6','axes.facecolor':'#faf9f6'})
def save(fig,name):
 fig.tight_layout(pad=2)
 fig.savefig(OUT/name,bbox_inches='tight',metadata={'Creator':'Chau Nguyen research portfolio; aggregate model results'})
 plt.close(fig)

counts=pd.read_csv(ROOT/'results/confusion.csv')
matrix=counts.pivot(index='Prediction',columns='Reference',values='Freq').loc[['No','Yes'],['No','Yes']]
fig,ax=plt.subplots(figsize=(7,5));ax.imshow(matrix,cmap='Greens',vmin=0)
for i in range(2):
 for j in range(2):ax.text(j,i,f'{matrix.iloc[i,j]:,}',ha='center',va='center',fontsize=26,color='white' if matrix.iloc[i,j]>2000 else '#243b36')
ax.set_xticks([0,1],['Legitimate','Fraud']);ax.set_yticks([0,1],['Legitimate','Fraud'])
ax.set_xlabel('Actual class');ax.set_ylabel('Predicted class')
ax.set_title('Random Forest · confusion matrix\n7,500 balanced held-out transactions',pad=18)
save(fig,'confusion.svg')
roc=pd.read_csv(ROOT/'results/roc.csv');metrics=pd.read_csv(ROOT/'results/metrics.csv').set_index('metric').value
fig,ax=plt.subplots(figsize=(7,5));ax.plot(roc.false_positive_rate,roc.true_positive_rate,color='#28645b',lw=2.5)
ax.plot([0,1],[0,1],ls='--',color='#a3a89c');ax.set(xlabel='False-positive rate',ylabel='True-positive rate',xlim=(0,1),ylim=(0,1),title=f'Random Forest ROC · AUC {metrics.roc_auc:.4f}\n7,500 balanced held-out transactions')
save(fig,'roc.svg')
imp=pd.read_csv(ROOT/'results/importance.csv').sort_values('mean_decrease_gini')
fig,ax=plt.subplots(figsize=(8,5));ax.barh(imp.feature.str.replace('_',' '),imp.mean_decrease_gini,color='#28645b');ax.set(xlabel='Mean decrease in Gini impurity',title='Random Forest feature importance\nDescriptive model importance')
save(fig,'importance.svg')
