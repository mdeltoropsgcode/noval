import { api, LightningElement } from 'lwc';
import getData from '@salesforce/apex/PSG_GetAccountLas90DaysActivity.getData';
import D3 from '@salesforce/resourceUrl/D3';
import { loadScript } from 'lightning/platformResourceLoader';

export default class Psg_ChartActivityLast90Days extends LightningElement {
    @api recordId; // Account ID
    data = {
        contacts: 0,
        opportunities: 0,
        showings: 0
    };
    d3Initialized = false;
    resizeObserver;
    chartRendered = false;

    connectedCallback() {
        this.fetchData();
    }

    disconnectedCallback() {
        // Limpia el observer cuando se desconecta el componente
        if (this.resizeObserver) {
            this.resizeObserver.disconnect();
        }
    }

    async fetchData() {
        try {
            const result = await getData({ accountId: this.recordId });
            this.data = result;
            this.initializeD3();
        } catch (e) {
            console.error('Error fetching data:', e);
        }
    }

    initializeD3() {
        if (this.d3Initialized) {
            this.renderChart();
            return;
        }

        loadScript(this, D3)
            .then(() => {
                this.d3Initialized = true;
                this.renderChart();
                this.setupResizeObserver();
            })
            .catch(error => {
                console.error('Error loading D3.js:', error);
            });
    }

    setupResizeObserver() {
        const chartContainer = this.template.querySelector('.chart');
        if (!chartContainer) return;

        // Usa ResizeObserver para manejar cambios de tamaño
        this.resizeObserver = new ResizeObserver(() => {
            if (this.chartRendered) {
                this.renderChart();
            }
        });
        
        this.resizeObserver.observe(chartContainer);
    }

    renderChart() {
        const chartContainer = this.template.querySelector('.chart');
        if (!chartContainer) return;

        chartContainer.innerHTML = ''; // Limpia el contenedor antes de renderizar

        const data = [
            { name: 'Contacts', value: this.data.contacts },
            { name: 'Opportunities', value: this.data.opportunities },
            { name: 'Showings', value: this.data.showings }
        ];

        // Dimensiones básicas
        const containerRect = chartContainer.getBoundingClientRect();
        const containerWidth = containerRect.width || 400;
        const containerHeight = 300;

        const margin = { top: 20, right: 20, bottom: 50, left: 40 };
        const width = containerWidth - margin.left - margin.right;
        const height = containerHeight - margin.top - margin.bottom;

        // Crear SVG
        const svg = d3
            .select(chartContainer)
            .append('svg')
            .attr('width', containerWidth)
            .attr('height', containerHeight);

        // Escalas
        const x = d3
            .scaleBand()
            .domain(data.map(d => d.name))
            .range([margin.left, width + margin.left])
            .padding(0.3);

        const maxValue = d3.max(data, d => d.value) || 1;
        const y = d3
            .scaleLinear()
            .domain([0, maxValue])
            .nice()
            .range([height + margin.top, margin.top]);

        // Colores sólidos
        const colors = {
            'Contacts': '#76DED9',
            'Opportunities': '#0B192E',
            'Showings': '#4667EC'
        };

        // Barras
        svg.append('g')
            .selectAll('rect')
            .data(data)
            .join('rect')
            .attr('x', d => x(d.name))
            .attr('y', d => y(d.value))
            .attr('height', d => y(0) - y(d.value))
            .attr('width', x.bandwidth())
            .attr('fill', d => colors[d.name]);

        // Etiquetas de valores
        svg.append('g')
            .selectAll('text')
            .data(data)
            .join('text')
            .attr('x', d => x(d.name) + x.bandwidth() / 2)
            .attr('y', d => y(d.value) - 5)
            .attr('text-anchor', 'middle')
            .style('font-size', '12px')
            .style('font-weight', 'bold')
            .text(d => d.value);

        // Eje Y
        svg.append('g')
            .attr('transform', `translate(${margin.left}, 0)`)
            .call(d3.axisLeft(y).ticks(5).tickFormat(d3.format('d')))
            .style('font-size', '10px');

        // Eje X
        svg.append('g')
            .attr('transform', `translate(0, ${height + margin.top})`)
            .call(d3.axisBottom(x))
            .style('font-size', '10px');

        this.chartRendered = true;
    }
}