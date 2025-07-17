import { LightningElement, api } from 'lwc';

export default class SimpleChart extends LightningElement {
    @api chartData;
    @api chartTitle;

    get hasData() {
        return this.chartData && this.chartData.length > 0;
    }

    get totalValue() {
        if (!this.hasData) return 0;
        return this.chartData.reduce((sum, item) => sum + item.value, 0);
    }

    get chartItems() {
        if (!this.hasData) return [];
        
        const total = this.totalValue;
        const maxValue = Math.max(...this.chartData.map(item => item.value));
        
        return this.chartData.map((item, index) => {
            const percentage = (item.value / total) * 100;
            const barWidth = (item.value / maxValue) * 100;
            
            return {
                ...item,
                percentage: percentage.toFixed(1),
                barWidth: barWidth.toFixed(1)
            };
        });
    }
}
