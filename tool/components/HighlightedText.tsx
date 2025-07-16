import React from 'react';
import { StringDiff } from '../utils/types/index';

interface HighlightedTextProps {
  diffs: StringDiff[];
  className?: string;
  style?: React.CSSProperties;
}

export const HighlightedText: React.FC<HighlightedTextProps> = ({
  diffs,
  className,
  style
}) => {
  const getStyleForDiffType = (diffType: StringDiff['type']): React.CSSProperties => {
    switch (diffType) {
      case 'added':
        return {
          backgroundColor: '#DCFCE7', // green-100
          color: '#166534', // green-800
          padding: '1px 2px',
          borderRadius: '2px'
        };
      case 'removed':
        return {
          backgroundColor: '#FEE2E2', // red-100
          color: '#DC2626', // red-600
          textDecoration: 'line-through',
          padding: '1px 2px',
          borderRadius: '2px'
        };
      case 'modified':
        return {
          backgroundColor: '#FEF3C7', // yellow-100
          color: '#D97706', // yellow-600
          padding: '1px 2px',
          borderRadius: '2px'
        };
      case 'unchanged':
      default:
        return {};
    }
  };

  return (
    <span className={className} style={style}>
      {diffs.map((diff, index) => (
        <span
          key={index}
          style={getStyleForDiffType(diff.type)}
          title={diff.type !== 'unchanged' ? `${diff.type}: "${diff.value}"` : undefined}
        >
          {diff.value}
        </span>
      ))}
    </span>
  );
};
