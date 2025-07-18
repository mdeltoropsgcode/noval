import { LightningElement } from 'lwc';

export default class ProductReports extends LightningElement {

    products = [
        {
            id: 1,
            name: 'Nike Air Max 270',
            category: 'Sport & Outdoor',
            stock: 50,
            status: 'Inactive',
            statusClass: 'status-inactive',
            styleMap: { animationDelay: '0s' }
        },
        {
            id: 2,
            name: 'Dell XPS 13',
            category: 'PC & Laptop',
            stock: 53,
            status: 'Active',
            statusClass: 'status-active',
            styleMap: { animationDelay: '0.1s' }
        },
        {
            id: 3,
            name: 'Sony A7 III',
            category: 'Photography',
            stock: 113,
            status: 'Active',
            statusClass: 'status-active',
            styleMap: { animationDelay: '0.2s' }
        },
        {
            id: 4,
            name: 'Apple MacBook Pro',
            category: 'PC & Laptop',
            stock: 97,
            status: 'Inactive',
            statusClass: 'status-inactive',
            styleMap: { animationDelay: '0.3s' }
        },
        {
            id: 4,
            name: 'Apple MacBook Pro',
            category: 'PC & Laptop',
            stock: 97,
            status: 'Inactive',
            statusClass: 'status-inactive',
            styleMap: { animationDelay: '0.3s' }
        },
        {
            id: 4,
            name: 'Apple MacBook Pro',
            category: 'PC & Laptop',
            stock: 97,
            status: 'Inactive',
            statusClass: 'status-inactive',
            styleMap: { animationDelay: '0.3s' }
        }
      
        
    ];
    
}